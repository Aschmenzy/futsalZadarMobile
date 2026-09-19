import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// A single upstream subscription multiplexed to every subscriber.
///
/// Used for live match documents: the home card, the league list row and the
/// match detail page all watch the same Firestore document, and each separate
/// listener is billed its own read for every write to that document. Routing
/// them through one instance collapses that to a single listener.
///
/// The source is subscribed on the first listener and dropped [idleGrace]
/// after the last one leaves. The latest value is replayed to late joiners, so
/// a row that subscribes mid-match shows the current score immediately instead
/// of waiting for the next write.
class SharedMatchStream<T> {
  /// Widget rebuilds cancel and resubscribe in the same frame. Holding the
  /// subscription briefly bridges that gap instead of paying for a fresh read.
  static const defaultIdleGrace = Duration(seconds: 10);

  final Stream<T> Function() _create;
  final void Function() _onExpired;
  final Duration _idleGrace;
  final BehaviorSubject<T> _subject = BehaviorSubject<T>();

  StreamSubscription<T>? _source;
  Timer? _idle;
  int _listeners = 0;

  SharedMatchStream(
    this._create,
    this._onExpired, {
    Duration idleGrace = defaultIdleGrace,
  }) : _idleGrace = idleGrace;

  Stream<T> get stream => _subject.doOnListen(_retain).doOnCancel(_release);

  /// Whether the upstream subscription is currently open.
  bool get isConnected => _source != null;

  int get listenerCount => _listeners;

  void _retain() {
    _idle?.cancel();
    _idle = null;
    _listeners++;
    _source ??= _create().listen(_subject.add, onError: _subject.addError);
  }

  void _release() {
    if (--_listeners > 0) return;
    _idle = Timer(_idleGrace, () {
      if (_listeners > 0) return;
      _onExpired();
      _source?.cancel();
      _source = null;
      _subject.close();
    });
  }
}
