class MatchPlayer {
  final String id;
  final String name;

  const MatchPlayer({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory MatchPlayer.fromJson(Map<String, dynamic> map) =>
      MatchPlayer(id: map['id']?.toString() ?? '', name: map['name']?.toString() ?? '');

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

  Map<String, dynamic> toJson() => {
    'goals': goals,
    'goals6m': goals6m,
    'goals10m': goals10m,
    'ownGoals': ownGoals,
    'fouls': fouls,
    'yellowCards': yellowCards,
    'redCards': redCards,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> map) => PlayerStats(
    goals: map['goals'] as int? ?? 0,
    goals6m: map['goals6m'] as int? ?? 0,
    goals10m: map['goals10m'] as int? ?? 0,
    ownGoals: map['ownGoals'] as int? ?? 0,
    fouls: map['fouls'] as int? ?? 0,
    yellowCards: map['yellowCards'] as int? ?? 0,
    redCards: map['redCards'] as int? ?? 0,
  );

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