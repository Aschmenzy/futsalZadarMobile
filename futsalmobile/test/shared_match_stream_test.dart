import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:futsalmobile/services/shared_match_stream.dart';

void main() {
  /// Counts how many times the upstream (the billed Firestore listener) is
  /// actually subscribed, and lets the test push values to every subscriber.
  ({
    SharedMatchStream<int> shared,
    int Function() subscribeCount,
    int Function() expiredCount,
    void Function(int) emit,
  })
  build({Duration grace = const Duration(milliseconds: 50)}) {
    var subscribes = 0;
    var expired = 0;
    final controller = StreamController<int>.broadcast();
    final shared = SharedMatchStream<int>(
      () {
        subscribes++;
        return controller.stream;
      },
      () => expired++,
      idleGrace: grace,
    );
    return (
      shared: shared,
      subscribeCount: () => subscribes,
      expiredCount: () => expired,
      emit: controller.add,
    );
  }

  test('three listeners share a single upstream subscription', () async {
    final h = build();
    final seen = [<int>[], <int>[], <int>[]];

    final subs = [
      h.shared.stream.listen(seen[0].add),
      h.shared.stream.listen(seen[1].add),
      h.shared.stream.listen(seen[2].add),
    ];
    await Future<void>.delayed(Duration.zero);

    h.emit(1);
    await Future<void>.delayed(Duration.zero);

    expect(h.subscribeCount(), 1, reason: 'only one billed listener');
    expect(h.shared.listenerCount, 3);
    for (final s in seen) {
      expect(s, [1]);
    }

    for (final s in subs) {
      await s.cancel();
    }
  });

  test('a late joiner is replayed the latest value', () async {
    final h = build();
    final first = h.shared.stream.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    h.emit(7);
    await Future<void>.delayed(Duration.zero);

    final late = <int>[];
    final second = h.shared.stream.listen(late.add);
    await Future<void>.delayed(Duration.zero);

    expect(late, [7], reason: 'joins mid-match with the current score');
    expect(h.subscribeCount(), 1);

    await first.cancel();
    await second.cancel();
  });

  test('a rebuild inside the grace period does not resubscribe', () async {
    final h = build();
    final first = h.shared.stream.listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(h.subscribeCount(), 1);

    // StreamBuilder cancels the old subscription and immediately opens a new
    // one when its widget rebuilds.
    await first.cancel();
    final second = h.shared.stream.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    expect(h.subscribeCount(), 1, reason: 'no second billed read');
    expect(h.shared.isConnected, isTrue);

    await second.cancel();
  });

  test('upstream is dropped once the last listener is gone', () async {
    final h = build();
    final sub = h.shared.stream.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(h.shared.isConnected, isTrue, reason: 'still inside the grace');

    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(h.shared.isConnected, isFalse);
    expect(h.expiredCount(), 1, reason: 'evicts itself from the watch map');
  });
}
