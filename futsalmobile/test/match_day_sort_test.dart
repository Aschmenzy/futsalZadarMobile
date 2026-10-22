import 'package:flutter_test/flutter_test.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/pages/matchesPage/match_page.dart';

MatchData _m(String id, String status, String time) => MatchData.fromJson({
  'matchId': id,
  'status': status,
  'matchDate': '2026-10-25',
  'matchTime': time,
});

void main() {
  test('live first, then upcoming, then finished — each by kickoff', () {
    final day = [
      _m('fin18', 'finished', '18:00'),
      _m('sched21', 'scheduled', '21:00'),
      _m('live20', 'ongoing', '20:00'),
      _m('fin17', 'finished', '17:00'),
      _m('sched19', 'scheduled', '19:00'),
      _m('paused19', 'paused', '19:00'),
      _m('postponed16', 'postponed', '16:00'),
    ];
    sortDayMatches(day);
    expect(day.map((m) => m.matchId), [
      'paused19',
      'live20',
      'sched19',
      'sched21',
      'postponed16',
      'fin17',
      'fin18',
    ]);
  });

  test('a fresher status moves a match that just finished to the end', () {
    final day = [
      _m('live18', 'ongoing', '18:00'),
      _m('sched20', 'scheduled', '20:00'),
    ];
    sortDayMatches(
      day,
      statusOf: (m) => m.matchId == 'live18' ? 'finished' : m.status,
    );
    expect(day.map((m) => m.matchId), ['sched20', 'live18']);
  });
}
