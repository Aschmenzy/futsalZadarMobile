import 'match_player.dart';
import 'match_state.dart';

class MatchData {
  final String matchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String league;
  final String leagueCode;
  final String season;
  final int round;
  final String matchDate;
  final String matchTime;
  final String status;
  final String homeTeam;
  final String homeTeamLogo;
  final int homeTeamGoals;
  final String awayTeam;
  final String awayTeamLogo;
  final int awayTeamGoals;
  final String delegate;
  final String? referee1;
  final String? referee2;

  // null when status is "scheduled"
  final MatchState? matchState;

  // populated when status is "finished"
  final int? originalHomeScore;
  final int? originalAwayScore;
  final Map<String, PlayerStats>? originalPlayerStats;
  final bool? statsProcessed;
  final DateTime? statsProcessedAt;

  const MatchData({
    required this.matchId,
    required this.createdAt,
    required this.updatedAt,
    required this.league,
    required this.leagueCode,
    required this.season,
    required this.round,
    required this.matchDate,
    required this.matchTime,
    required this.status,
    required this.homeTeam,
    required this.homeTeamLogo,
    required this.homeTeamGoals,
    required this.awayTeam,
    required this.awayTeamLogo,
    required this.awayTeamGoals,
    required this.delegate,
    this.referee1,
    this.referee2,
    this.matchState,
    this.originalHomeScore,
    this.originalAwayScore,
    this.originalPlayerStats,
    this.statsProcessed,
    this.statsProcessedAt,
  });

  String get score => '$homeTeamGoals : $awayTeamGoals';

  bool get isScheduled => status == 'scheduled';
  bool get isLive => status == 'live';
  bool get isFinished => status == 'finished';

  factory MatchData.fromFirestore(Map<String, dynamic> map, String docId) {
    Map<String, PlayerStats>? originalStats;
    if (map['originalPlayerStats'] != null) {
      originalStats = {};
      (map['originalPlayerStats'] as Map<String, dynamic>).forEach((k, v) {
        originalStats![k] = PlayerStats.fromFirestore(
          v as Map<String, dynamic>,
        );
      });
    }

    return MatchData(
      matchId: docId,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      league: map['league'] ?? '',
      leagueCode: map['leagueCode'] ?? '',
      season: map['season'] ?? '',
      round: map['round'] ?? 0,
      matchDate: map['matchDate'] ?? '',
      matchTime: map['matchTime'] ?? '',
      status: map['status'] ?? '',
      homeTeam: map['homeTeam'] ?? '',
      homeTeamLogo: map['homeTeamLogo'] ?? '',
      homeTeamGoals: map['homeTeamGoals'] ?? 0,
      awayTeam: map['awayTeam'] ?? '',
      awayTeamLogo: map['awayTeamLogo'] ?? '',
      awayTeamGoals: map['awayTeamGoals'] ?? 0,
      delegate: map['delegate'] ?? '',
      referee1: map['referee1'],
      referee2: map['referee2'],
      matchState: map['matchState'] != null
          ? MatchState.fromFirestore(map['matchState'] as Map<String, dynamic>)
          : null,
      originalHomeScore: map['originalHomeScore'],
      originalAwayScore: map['originalAwayScore'],
      originalPlayerStats: originalStats,
      statsProcessed: map['statsProcessed'],
      statsProcessedAt: map['statsProcessedAt'] != null
          ? (map['statsProcessedAt'] as dynamic).toDate()
          : null,
    );
  }
}
