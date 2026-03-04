class MatchPlayer {
  final String id;
  final String name;

  const MatchPlayer({
    required this.id,
    required this.name,
  });

  factory MatchPlayer.fromFirestore(Map<String, dynamic> map) {
    return MatchPlayer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}

class PlayerStats {
  final int goals;
  final int goals6m;
  final int goals10m;
  final int ownGoals;
  final int fouls;
  final int yellowCards;
  final int redCards;

  const PlayerStats({
    this.goals = 0,
    this.goals6m = 0,
    this.goals10m = 0,
    this.ownGoals = 0,
    this.fouls = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  factory PlayerStats.fromFirestore(Map<String, dynamic> map) {
    return PlayerStats(
      goals: map['goals'] ?? 0,
      goals6m: map['goals6m'] ?? 0,
      goals10m: map['goals10m'] ?? 0,
      ownGoals: map['ownGoals'] ?? 0,
      fouls: map['fouls'] ?? 0,
      yellowCards: map['yellowCards'] ?? 0,
      redCards: map['redCards'] ?? 0,
    );
  }
}