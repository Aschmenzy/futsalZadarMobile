class PlayerStatsData {
  final String id;
  final String clubName;
  final num fouls;
  final num goals;
  final num goals10m;
  final num goals6m;
  final num matchesPlayed;
  final String playerId;
  final num ownGoals;
  final String playerFullName;
  final num redCards;
  final num yellowCards;
  final num activeYellows;
  final num suspendedUntilRound;

  const PlayerStatsData({
    required this.id,
    required this.clubName,
    required this.fouls,
    required this.goals,
    required this.goals10m,
    required this.goals6m,
    required this.matchesPlayed,
    required this.playerId,
    required this.ownGoals,
    required this.playerFullName,
    required this.redCards,
    required this.yellowCards,
    required this.suspendedUntilRound,
    required this.activeYellows,
  });

  num get totalGoals => goals + goals10m + goals6m;

  factory PlayerStatsData.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    return PlayerStatsData(
      id: docId,
      clubName: map['clubName'] as String? ?? '',
      fouls: map['fouls'] as num? ?? 0,
      goals: map['goals'] as num? ?? 0,
      goals10m: map['goals10m'] as num? ?? 0,
      goals6m: map['goals6m'] as num? ?? 0,
      matchesPlayed: map['matchesPlayed'] as num? ?? 0,
      playerId: map['odFCplayerId'] as String? ?? '',
      ownGoals: map['ownGoals'] as num? ?? 0,
      playerFullName: map['playerName'] as String? ?? '',
      redCards: map['redCards'] as num? ?? 0,
      yellowCards: map['yellowCards'] as num? ?? 0,
      activeYellows: map['activeYellows'] as num,
      suspendedUntilRound: map['suspendedUntilRound'] as num? ?? 0,
    );
  }
}
