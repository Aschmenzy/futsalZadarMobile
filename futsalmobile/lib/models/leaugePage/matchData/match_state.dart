import 'match_event.dart';
import 'match_player.dart';

class MatchState {
  final String status;          // "scheduled" | "live" | "finished" | "postponed" | "cancelled"
  final String currentPeriod;   // "1st" | "2nd" | "ot" | "penalties"

  final bool isConfirmed;
  final DateTime? confirmedAt;
  final bool isPaused;

  final int timerDuration;      // seconds
  final int timerRemaining;     // seconds
  final DateTime timerStartedAt;
  final DateTime updatedAt;

  final List<MatchPlayer> homeTeamPlayers;
  final List<String> homeInPlay;                  // player IDs currently on field
  final Map<String, String> homeShirtNumbers;     // { playerId: shirtNumber }
  final int homeTeamFouls1st;
  final int homeTeamFouls2nd;

  final List<MatchPlayer> awayTeamPlayers;
  final List<String> awayInPlay;
  final Map<String, String> awayShirtNumbers;
  final int awayTeamFouls1st;
  final int awayTeamFouls2nd;

  final List<MatchEvent> events;
  final Map<String, PlayerStats> playerStats;     // { playerId: PlayerStats }

  const MatchState({
    required this.status,
    required this.currentPeriod,
    required this.isConfirmed,
    this.confirmedAt,
    required this.isPaused,
    required this.timerDuration,
    required this.timerRemaining,
    required this.timerStartedAt,
    required this.updatedAt,
    required this.homeTeamPlayers,
    required this.homeInPlay,
    required this.homeShirtNumbers,
    required this.homeTeamFouls1st,
    required this.homeTeamFouls2nd,
    required this.awayTeamPlayers,
    required this.awayInPlay,
    required this.awayShirtNumbers,
    required this.awayTeamFouls1st,
    required this.awayTeamFouls2nd,
    required this.events,
    required this.playerStats,
  });

  factory MatchState.fromFirestore(Map<String, dynamic> map) {
    final homeShirts = <String, String>{};
    (map['homeShirtNumbers'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      homeShirts[k] = v.toString();
    });

    final awayShirts = <String, String>{};
    (map['awayShirtNumbers'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      awayShirts[k] = v.toString();
    });

    final stats = <String, PlayerStats>{};
    (map['playerStats'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      stats[k] = PlayerStats.fromFirestore(v as Map<String, dynamic>);
    });

    return MatchState(
      status: map['status'] ?? '',
      currentPeriod: map['currentPeriod'] ?? '',
      isConfirmed: map['isConfirmed'] ?? false,
      confirmedAt: map['confirmedAt'] != null
          ? DateTime.parse(map['confirmedAt'])
          : null,
      isPaused: map['isPaused'] ?? false,
      timerDuration: map['timerDuration'] ?? 0,
      timerRemaining: map['timerRemaining'] ?? 0,
      timerStartedAt: DateTime.parse(map['timerStartedAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      homeTeamPlayers: (map['homeTeamPlayers'] as List<dynamic>? ?? [])
          .map((p) => MatchPlayer.fromFirestore(p as Map<String, dynamic>))
          .toList(),
      homeInPlay: List<String>.from(map['homeInPlay'] ?? []),
      homeShirtNumbers: homeShirts,
      homeTeamFouls1st: map['homeTeamFouls1st'] ?? 0,
      homeTeamFouls2nd: map['homeTeamFouls2nd'] ?? 0,
      awayTeamPlayers: (map['awayTeamPlayers'] as List<dynamic>? ?? [])
          .map((p) => MatchPlayer.fromFirestore(p as Map<String, dynamic>))
          .toList(),
      awayInPlay: List<String>.from(map['awayInPlay'] ?? []),
      awayShirtNumbers: awayShirts,
      awayTeamFouls1st: map['awayTeamFouls1st'] ?? 0,
      awayTeamFouls2nd: map['awayTeamFouls2nd'] ?? 0,
      events: (map['events'] as List<dynamic>? ?? [])
          .map((e) => MatchEvent.fromFirestore(e as Map<String, dynamic>))
          .toList(),
      playerStats: stats,
    );
  }
}