class PlayoffTeam {
  final String clubId;
  final String clubLogo;
  final String clubName;
  final int? position;

  const PlayoffTeam({
    required this.clubId,
    required this.clubLogo,
    required this.clubName,
    this.position,
  });

  factory PlayoffTeam.fromMap(Map<String, dynamic> map) {
    return PlayoffTeam(
      clubId: map['clubId'] as String? ?? '',
      clubLogo: map['clubLogo'] as String? ?? '',
      clubName: map['clubName'] as String? ?? '',
      position: map['position'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'clubLogo': clubLogo,
        'clubName': clubName,
        'position': position,
      };

  factory PlayoffTeam.fromJson(Map<String, dynamic> json) {
    return PlayoffTeam(
      clubId: json['clubId']?.toString() ?? '',
      clubLogo: json['clubLogo']?.toString() ?? '',
      clubName: json['clubName']?.toString() ?? '',
      position: (json['position'] as num?)?.toInt(),
    );
  }
}

class PlayoffTie {
  final String id;
  final String round; // "qf", "sf", "final", "3rd_place"
  final String status;
  final PlayoffTeam? teamA;
  final PlayoffTeam? teamB;
  final int? aggregateA;
  final int? aggregateB;
  final bool isSingleLeg;
  final String? leg1MatchId;
  final int? leg1ScoreA;
  final int? leg1ScoreB;
  final String? leg2MatchId;
  final int? leg2ScoreA;
  final int? leg2ScoreB;
  final String? penaltiesMatchId;
  final int? penaltiesScoreA;
  final int? penaltiesScoreB;
  final String? winner; // clubId of winner, or null

  const PlayoffTie({
    required this.id,
    required this.round,
    required this.status,
    this.teamA,
    this.teamB,
    this.aggregateA,
    this.aggregateB,
    this.isSingleLeg = false,
    this.leg1MatchId,
    this.leg1ScoreA,
    this.leg1ScoreB,
    this.leg2MatchId,
    this.leg2ScoreA,
    this.leg2ScoreB,
    this.penaltiesMatchId,
    this.penaltiesScoreA,
    this.penaltiesScoreB,
    this.winner,
  });

  factory PlayoffTie.fromFirestore(String id, Map<String, dynamic> data) {
    final teamAData = data['teamA'] as Map<String, dynamic>?;
    final teamBData = data['teamB'] as Map<String, dynamic>?;

    return PlayoffTie(
      id: id,
      round: data['round'] as String? ?? '',
      status: data['status'] as String? ?? '',
      teamA: teamAData != null ? PlayoffTeam.fromMap(teamAData) : null,
      teamB: teamBData != null ? PlayoffTeam.fromMap(teamBData) : null,
      aggregateA: data['aggregateA'] as int?,
      aggregateB: data['aggregateB'] as int?,
      isSingleLeg: data['isSingleLeg'] as bool? ?? false,
      leg1MatchId: data['leg1MatchId'] as String?,
      leg1ScoreA: data['leg1ScoreA'] as int?,
      leg1ScoreB: data['leg1ScoreB'] as int?,
      leg2MatchId: data['leg2MatchId'] as String?,
      leg2ScoreA: data['leg2ScoreA'] as int?,
      leg2ScoreB: data['leg2ScoreB'] as int?,
      penaltiesMatchId: data['penaltiesMatchId'] as String?,
      penaltiesScoreA: data['penaltiesScoreA'] as int?,
      penaltiesScoreB: data['penaltiesScoreB'] as int?,
      winner: data['winner'] as String?,
    );
  }

  /// Canonical, JSON-safe shape for the Hive cache. Every field is a
  /// String/int/bool/null, so this round-trips through jsonEncode losslessly.
  Map<String, dynamic> toJson() => {
        'id': id,
        'round': round,
        'status': status,
        'teamA': teamA?.toJson(),
        'teamB': teamB?.toJson(),
        'aggregateA': aggregateA,
        'aggregateB': aggregateB,
        'isSingleLeg': isSingleLeg,
        'leg1MatchId': leg1MatchId,
        'leg1ScoreA': leg1ScoreA,
        'leg1ScoreB': leg1ScoreB,
        'leg2MatchId': leg2MatchId,
        'leg2ScoreA': leg2ScoreA,
        'leg2ScoreB': leg2ScoreB,
        'penaltiesMatchId': penaltiesMatchId,
        'penaltiesScoreA': penaltiesScoreA,
        'penaltiesScoreB': penaltiesScoreB,
        'winner': winner,
      };

  factory PlayoffTie.fromJson(Map<String, dynamic> json) {
    final teamAData = json['teamA'];
    final teamBData = json['teamB'];

    return PlayoffTie(
      id: json['id']?.toString() ?? '',
      round: json['round']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      teamA: teamAData is Map
          ? PlayoffTeam.fromJson(Map<String, dynamic>.from(teamAData))
          : null,
      teamB: teamBData is Map
          ? PlayoffTeam.fromJson(Map<String, dynamic>.from(teamBData))
          : null,
      aggregateA: (json['aggregateA'] as num?)?.toInt(),
      aggregateB: (json['aggregateB'] as num?)?.toInt(),
      isSingleLeg: json['isSingleLeg'] == true,
      leg1MatchId: json['leg1MatchId'] as String?,
      leg1ScoreA: (json['leg1ScoreA'] as num?)?.toInt(),
      leg1ScoreB: (json['leg1ScoreB'] as num?)?.toInt(),
      leg2MatchId: json['leg2MatchId'] as String?,
      leg2ScoreA: (json['leg2ScoreA'] as num?)?.toInt(),
      leg2ScoreB: (json['leg2ScoreB'] as num?)?.toInt(),
      penaltiesMatchId: json['penaltiesMatchId'] as String?,
      penaltiesScoreA: (json['penaltiesScoreA'] as num?)?.toInt(),
      penaltiesScoreB: (json['penaltiesScoreB'] as num?)?.toInt(),
      winner: json['winner'] as String?,
    );
  }

  /// Returns all non-null match IDs associated with this tie.
  List<String> get allMatchIds {
    return [
      if (leg1MatchId != null) leg1MatchId!,
      if (leg2MatchId != null) leg2MatchId!,
      if (penaltiesMatchId != null) penaltiesMatchId!,
    ];
  }
}
