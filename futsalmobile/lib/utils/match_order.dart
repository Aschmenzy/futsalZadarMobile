import 'dart:async';

import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/services/firebase_services.dart';

bool isRunningStatus(String status) =>
    status == 'ongoing' || status == 'paused';

/// Live and paused first, then not yet started, then everything that is
/// over (finished, awarded, postponed, interrupted).
int _statusRank(String status) {
  if (isRunningStatus(status)) return 0;
  if (status == 'scheduled') return 1;
  return 2;
}

/// Orders one day's matches: live → upcoming → finished, each by kickoff.
/// [statusOf] lets the page supply a fresher status than the list's.
void sortDayMatches(
  List<MatchData> matches, {
  String Function(MatchData)? statusOf,
}) {
  final status = statusOf ?? (MatchData m) => m.status;
  matches.sort((a, b) {
    final byStatus = _statusRank(status(a)).compareTo(_statusRank(status(b)));
    if (byStatus != 0) return byStatus;
    return MatchData.byKickoff(a, b);
  });
}

/// Latest Firestore status of the matches the API list shows as running.
///
/// The list can lag behind: a match that just finished can still come back
/// as "ongoing" until the next lastUpdatedMatches bump. Listening to the
/// running matches' docs (shared with the live cards' StreamBuilders, so no
/// extra reads) lets a page re-order or drop them as soon as they end.
class LiveStatusTracker {
  LiveStatusTracker(this._onChange);

  final void Function() _onChange;
  final _service = FirebaseService();
  final Map<String, String> _status = {};
  final Map<String, StreamSubscription<MatchData>> _subs = {};

  String statusOf(MatchData m) => _status[m.matchId] ?? m.status;

  /// Call with the matches currently shown. Starts listeners for the running
  /// ones, stops the rest, and forgets statuses a newer list has replaced.
  void watch(List<MatchData> shown) {
    final running = {
      for (final m in shown)
        if (isRunningStatus(m.status)) m.matchId: m,
    };
    _status.removeWhere((id, _) => !running.containsKey(id));
    for (final id in _subs.keys.toList()) {
      if (!running.containsKey(id)) _subs.remove(id)!.cancel();
    }
    for (final m in running.values) {
      _subs[m.matchId] ??= _service.watchMatch(m).listen((fresh) {
        if (statusOf(m) == fresh.status) return;
        _status[m.matchId] = fresh.status;
        _onChange();
      }, onError: (_) {});
    }
  }

  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
  }
}
