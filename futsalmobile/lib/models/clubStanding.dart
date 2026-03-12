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
