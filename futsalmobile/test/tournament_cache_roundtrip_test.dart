// Guards the Hive cache path for tournaments: every model cached under a
// 'tournaments_' key must survive jsonEncode → jsonDecode → fromJson exactly.
// A silent failure here would serve users corrupted brackets from cache.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/models/tournament/tournament_data.dart';

/// Mirrors what CacheService.setRaw/getRaw do to the payload.
List<Map<String, dynamic>> throughCache(List<Map<String, dynamic>> payload) {
  final decoded = jsonDecode(jsonEncode(payload)) as List;
  return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

void main() {
  test('TournamentData round-trips through the cache', () {
    const original = TournamentData(
      id: 'tour_1',
      name: 'Zimski kup',
      bracketSize: 16,
      format: 'knockout',
      seasonStamp: '2025/2026',
      status: 'in_progress',
      thirdPlace: true,
      isActive: true,
    );

    final restored =
        TournamentData.fromJson(throughCache([original.toJson()]).single);

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.bracketSize, original.bracketSize);
    expect(restored.format, original.format);
    expect(restored.seasonStamp, original.seasonStamp);
    expect(restored.status, original.status);
    expect(restored.thirdPlace, original.thirdPlace);
    expect(restored.isActive, original.isActive);
    // Derived getters must behave identically after a cache hit.
    expect(restored.isInProgress, isTrue);
    expect(restored.isFinished, isFalse);
  });

  test('TournamentData preserves isActive=false so archive stays archived', () {
    const archived = TournamentData(
      id: 'tour_old',
      name: 'Ljetni kup',
      bracketSize: 8,
      format: 'knockout',
      seasonStamp: '2023/2024',
      status: 'completed',
      thirdPlace: false,
      isActive: false,
    );

    final restored =
        TournamentData.fromJson(throughCache([archived.toJson()]).single);

    expect(restored.isActive, isFalse);
    expect(restored.isFinished, isTrue);
  });

  test('TournamentTeam and TournamentPlayer round-trip', () {
    const team = TournamentTeam(
      id: 'team_1',
      name: 'Futsal Zadar',
      logo: 'https://example.com/logo.png',
    );
    final restoredTeam =
        TournamentTeam.fromJson(throughCache([team.toJson()]).single);
    expect(restoredTeam.id, team.id);
    expect(restoredTeam.name, team.name);
    expect(restoredTeam.logo, team.logo);

    const player = TournamentPlayer(
      id: 'p1',
      name: 'Ivan Ivić',
      isProfessional: true,
    );
    final restoredPlayer =
        TournamentPlayer.fromJson(throughCache([player.toJson()]).single);
    expect(restoredPlayer.id, player.id);
    expect(restoredPlayer.name, player.name);
    expect(restoredPlayer.isProfessional, isTrue);
  });

  test('PlayoffTie round-trips with every field populated', () {
    const original = PlayoffTie(
      id: 'final',
      round: 'final',
      status: 'completed',
      teamA: PlayoffTeam(
        clubId: 'c1',
        clubLogo: 'https://example.com/a.png',
        clubName: 'Klub A',
        position: 1,
      ),
      teamB: PlayoffTeam(
        clubId: 'c2',
        clubLogo: 'https://example.com/b.png',
        clubName: 'Klub B',
        position: 2,
      ),
      aggregateA: 5,
      aggregateB: 4,
      isSingleLeg: false,
      leg1MatchId: 'm1',
      leg1ScoreA: 2,
      leg1ScoreB: 2,
      leg2MatchId: 'm2',
      leg2ScoreA: 3,
      leg2ScoreB: 2,
      penaltiesMatchId: 'm3',
      penaltiesScoreA: 4,
      penaltiesScoreB: 3,
      winner: 'c1',
    );

    final restored = PlayoffTie.fromJson(throughCache([original.toJson()]).single);

    expect(restored.id, original.id);
    expect(restored.round, original.round);
    expect(restored.status, original.status);
    expect(restored.teamA?.clubId, 'c1');
    expect(restored.teamA?.clubName, 'Klub A');
    expect(restored.teamA?.clubLogo, original.teamA?.clubLogo);
    expect(restored.teamA?.position, 1);
    expect(restored.teamB?.clubId, 'c2');
    expect(restored.teamB?.position, 2);
    expect(restored.aggregateA, 5);
    expect(restored.aggregateB, 4);
    expect(restored.isSingleLeg, isFalse);
    expect(restored.leg1MatchId, 'm1');
    expect(restored.leg1ScoreA, 2);
    expect(restored.leg1ScoreB, 2);
    expect(restored.leg2MatchId, 'm2');
    expect(restored.leg2ScoreA, 3);
    expect(restored.leg2ScoreB, 2);
    expect(restored.penaltiesMatchId, 'm3');
    expect(restored.penaltiesScoreA, 4);
    expect(restored.penaltiesScoreB, 3);
    expect(restored.winner, 'c1');
    expect(restored.allMatchIds, ['m1', 'm2', 'm3']);
  });

  test('PlayoffTie round-trips an empty, unplayed tie without crashing', () {
    // The common case for a freshly drawn bracket: no teams, no scores.
    const original = PlayoffTie(
      id: 'sf_1',
      round: 'sf',
      status: 'pending',
    );

    final restored = PlayoffTie.fromJson(throughCache([original.toJson()]).single);

    expect(restored.id, 'sf_1');
    expect(restored.round, 'sf');
    expect(restored.status, 'pending');
    expect(restored.teamA, isNull);
    expect(restored.teamB, isNull);
    expect(restored.aggregateA, isNull);
    expect(restored.winner, isNull);
    expect(restored.isSingleLeg, isFalse);
    expect(restored.allMatchIds, isEmpty);
  });

  test('PlayoffTeam with a null position survives the round-trip', () {
    const team = PlayoffTeam(clubId: 'c9', clubLogo: '', clubName: 'Klub C');
    final restored =
        PlayoffTeam.fromJson(throughCache([team.toJson()]).single);
    expect(restored.clubId, 'c9');
    expect(restored.clubName, 'Klub C');
    expect(restored.position, isNull);
  });
}
