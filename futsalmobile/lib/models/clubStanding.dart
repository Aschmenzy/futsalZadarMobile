class ClubStanding {
  final String clubId;
  final String clubLogo;
  final String clubName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int draws;
  final int goalDifference;
  final int goalsAgainst;
  final int goalsFor;
  final int losses;
  final int matchesPlayed;
  final int points;
  final int wins;
  /// Last N match results, e.g. ['W','L','D','L','W']
  final List<String> form;

  const ClubStanding({
    required this.clubId,
    required this.clubLogo,
    required this.clubName,
    required this.createdAt,
    required this.updatedAt,
    required this.draws,
    required this.goalDifference,
    required this.goalsAgainst,
    required this.goalsFor,
    required this.losses,
    required this.matchesPlayed,
    required this.points,
    required this.wins,
    this.form = const [],
  });

  factory ClubStanding.fromFirestore(Map<String, dynamic> map, String docId) {
    return ClubStanding(
      clubId: map['clubId'] as String? ?? docId,
      clubLogo: map['clubLogo'] as String? ?? '',
      clubName: map['clubName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      goalDifference: (map['goalDifference'] as num?)?.toInt() ?? 0,
      goalsAgainst: (map['goalsAgainst'] as num?)?.toInt() ?? 0,
      goalsFor: (map['goalsFor'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
      points: (map['points'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'clubId': clubId,
    'clubLogo': clubLogo,
    'clubName': clubName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'draws': draws,
    'goalDifference': goalDifference,
    'goalsAgainst': goalsAgainst,
    'goalsFor': goalsFor,
    'losses': losses,
    'matchesPlayed': matchesPlayed,
    'points': points,
    'wins': wins,
  };

  factory ClubStanding.fromJson(Map<String, dynamic> map) => ClubStanding(
    clubId: map['clubId'] as String,
    clubLogo: map['clubLogo'] as String,
    clubName: map['clubName'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    draws: map['draws'] as int,
    goalDifference: map['goalDifference'] as int,
    goalsAgainst: map['goalsAgainst'] as int,
    goalsFor: map['goalsFor'] as int,
    losses: map['losses'] as int,
    matchesPlayed: map['matchesPlayed'] as int,
    points: map['points'] as int,
    wins: map['wins'] as int,
  );

  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'clubLogo': clubLogo,
      'clubName': clubName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'draws': draws,
      'goalDifference': goalDifference,
      'goalsAgainst': goalsAgainst,
      'goalsFor': goalsFor,
      'losses': losses,
      'matchesPlayed': matchesPlayed,
      'points': points,
      'wins': wins,
    };
  }
}
