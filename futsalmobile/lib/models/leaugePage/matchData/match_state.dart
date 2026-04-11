import 'match_event.dart';
import 'match_player.dart';

class MatchState {
  final String status;
  final String currentPeriod;

  final bool isConfirmed;
  final DateTime? confirmedAt;
  final bool isPaused;

  final int timerDuration;
  final int timerRemaining;
  final DateTime timerStartedAt;
  final DateTime updatedAt;

  final List<MatchPlayer> homeTeamPlayers;
  final List<String> homeInPlay;
  final Map<String, String> homeShirtNumbers;
  final int homeTeamFouls1st;
  final int homeTeamFouls2nd;

  final List<MatchPlayer> awayTeamPlayers;
  final List<String> awayInPlay;
  final Map<String, String> awayShirtNumbers;
  final int awayTeamFouls1st;
  final int awayTeamFouls2nd;

  final List<MatchEvent> events;
  final Map<String, PlayerStats> playerStats;

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

  Map<String, dynamic> toJson() => {
    'status': status,
    'currentPeriod': currentPeriod,
    'isConfirmed': isConfirmed,
    'confirmedAt': confirmedAt?.toIso8601String(),
    'isPaused': isPaused,
    'timerDuration': timerDuration,
    'timerRemaining': timerRemaining,
    'timerStartedAt': timerStartedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'homeTeamPlayers': homeTeamPlayers.map((p) => p.toJson()).toList(),
    'homeInPlay': homeInPlay,
    'homeShirtNumbers': homeShirtNumbers,
    'homeTeamFouls1st': homeTeamFouls1st,
    'homeTeamFouls2nd': homeTeamFouls2nd,
    'awayTeamPlayers': awayTeamPlayers.map((p) => p.toJson()).toList(),
    'awayInPlay': awayInPlay,
    'awayShirtNumbers': awayShirtNumbers,
    'awayTeamFouls1st': awayTeamFouls1st,
    'awayTeamFouls2nd': awayTeamFouls2nd,
    'events': events.map((e) => e.toJson()).toList(),
    'playerStats': playerStats.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory MatchState.fromJson(Map<String, dynamic> map) {
    final homeShirts = <String, String>{};
    (map['homeShirtNumbers'] as Map? ?? {}).forEach((k, v) {
      homeShirts[k.toString()] = v.toString();
    });
    final awayShirts = <String, String>{};
    (map['awayShirtNumbers'] as Map? ?? {}).forEach((k, v) {
      awayShirts[k.toString()] = v.toString();
    });
    final stats = <String, PlayerStats>{};
    (map['playerStats'] as Map? ?? {}).forEach((k, v) {
      stats[k.toString()] = PlayerStats.fromJson(Map<String, dynamic>.from(v as Map));
    });
    return MatchState(
      status: map['status'] as String? ?? '',
      currentPeriod: map['currentPeriod'] as String? ?? '',
      isConfirmed: map['isConfirmed'] as bool? ?? false,
      confirmedAt: map['confirmedAt'] != null
          ? DateTime.parse(map['confirmedAt'] as String)
          : null,
      isPaused: map['isPaused'] as bool? ?? false,
      timerDuration: map['timerDuration'] as int? ?? 0,
      timerRemaining: map['timerRemaining'] as int? ?? 0,
      timerStartedAt: DateTime.parse(map['timerStartedAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      homeTeamPlayers: (map['homeTeamPlayers'] as List? ?? [])
          .map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      homeInPlay: (map['homeInPlay'] as List? ?? []).map((e) => e.toString()).toList(),
      homeShirtNumbers: homeShirts,
      homeTeamFouls1st: map['homeTeamFouls1st'] as int? ?? 0,
      homeTeamFouls2nd: map['homeTeamFouls2nd'] as int? ?? 0,
      awayTeamPlayers: (map['awayTeamPlayers'] as List? ?? [])
          .map((p) => MatchPlayer.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      awayInPlay: (map['awayInPlay'] as List? ?? []).map((e) => e.toString()).toList(),
      awayShirtNumbers: awayShirts,
      awayTeamFouls1st: map['awayTeamFouls1st'] as int? ?? 0,
      awayTeamFouls2nd: map['awayTeamFouls2nd'] as int? ?? 0,
      events: (map['events'] as List? ?? [])
          .map((e) => MatchEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      playerStats: stats,
    );
  }

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
      status: map['status'] as String? ?? '',
      currentPeriod: map['currentPeriod'] as String? ?? '',
      isConfirmed: map['isConfirmed'] as bool? ?? false,
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] is String
                ? DateTime.parse(map['confirmedAt'] as String)
                : (map['confirmedAt'] as dynamic).toDate())
          : null,
      isPaused: map['isPaused'] as bool? ?? false,
      timerDuration: map['timerDuration'] as int? ?? 0,
      timerRemaining: map['timerRemaining'] as int? ?? 0,
      timerStartedAt: map['timerStartedAt'] != null
          ? (map['timerStartedAt'] is String
                ? DateTime.parse(map['timerStartedAt'] as String)
                : (map['timerStartedAt'] as dynamic).toDate())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is String
                ? DateTime.parse(map['updatedAt'] as String)
                : (map['updatedAt'] as dynamic).toDate())
          : DateTime.now(),
      homeTeamPlayers: (map['homeTeamPlayers'] as List<dynamic>? ?? [])
          .map((p) => MatchPlayer.fromFirestore(p as Map<String, dynamic>))
          .toList(),
      homeInPlay: (map['homeInPlay'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      homeShirtNumbers: homeShirts,
      homeTeamFouls1st: map['homeTeamFouls1st'] as int? ?? 0,
      homeTeamFouls2nd: map['homeTeamFouls2nd'] as int? ?? 0,
      awayTeamPlayers: (map['awayTeamPlayers'] as List<dynamic>? ?? [])
          .map((p) => MatchPlayer.fromFirestore(p as Map<String, dynamic>))
          .toList(),
      awayInPlay: (map['awayInPlay'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      awayShirtNumbers: awayShirts,
      awayTeamFouls1st: map['awayTeamFouls1st'] as int? ?? 0,
      awayTeamFouls2nd: map['awayTeamFouls2nd'] as int? ?? 0,
      events: (map['events'] as List<dynamic>? ?? [])
          .map((e) => MatchEvent.fromFirestore(e as Map<String, dynamic>))
          .toList(),
      playerStats: stats,
    );
  }
}
