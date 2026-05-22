class PlayoffGroupClub {
  final String clubId;
  final String clubName;
  final String clubLogo;

  const PlayoffGroupClub({
    required this.clubId,
    required this.clubName,
    required this.clubLogo,
  });

  factory PlayoffGroupClub.fromMap(Map<String, dynamic> map) => PlayoffGroupClub(
        clubId: map['clubId'] as String? ?? '',
        clubName: map['clubName'] as String? ?? '',
        clubLogo: map['clubLogo'] as String? ?? '',
      );
}

class PlayoffGroupStanding {
  final String clubId;
  final String clubName;
  final String clubLogo;
  // "upper" or "lower" — which source league the team came from
  final String league;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  int get goalDiff => goalsFor - goalsAgainst;

  const PlayoffGroupStanding({
    required this.clubId,
    required this.clubName,
    required this.clubLogo,
    required this.league,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
  });

  factory PlayoffGroupStanding.fromMap(String clubId, Map<String, dynamic> map) =>
      PlayoffGroupStanding(
        clubId: clubId,
        clubName: map['clubName'] as String? ?? '',
        clubLogo: map['clubLogo'] as String? ?? '',
        league: map['league'] as String? ?? '',
        played: map['played'] as int? ?? 0,
        wins: map['wins'] as int? ?? 0,
        draws: map['draws'] as int? ?? 0,
        losses: map['losses'] as int? ?? 0,
        goalsFor: map['goalsFor'] as int? ?? 0,
        goalsAgainst: map['goalsAgainst'] as int? ?? 0,
        points: map['points'] as int? ?? 0,
      );
}

class PlayoffGroupData {
  final String label;
  final String upperLeague;
  final String lowerLeague;
  final List<PlayoffGroupStanding> standings;
  final List<PlayoffGroupClub> autoPromoted;
  final List<PlayoffGroupClub> autoRelegated;

  const PlayoffGroupData({
    required this.label,
    required this.upperLeague,
    required this.lowerLeague,
    required this.standings,
    required this.autoPromoted,
    required this.autoRelegated,
  });

  factory PlayoffGroupData.fromFirestore(Map<String, dynamic> map) {
    final standingsMap = map['standings'] as Map<String, dynamic>? ?? {};
    final standings = standingsMap.entries
        .map((e) => PlayoffGroupStanding.fromMap(
              e.key,
              Map<String, dynamic>.from(e.value as Map),
            ))
        .toList()
      ..sort((a, b) {
        final pts = b.points.compareTo(a.points);
        if (pts != 0) return pts;
        final diff = b.goalDiff.compareTo(a.goalDiff);
        if (diff != 0) return diff;
        return b.goalsFor.compareTo(a.goalsFor);
      });

    List<PlayoffGroupClub> parseClubs(dynamic raw) {
      if (raw == null) return [];
      return (raw as List)
          .map((e) => PlayoffGroupClub.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return PlayoffGroupData(
      label: map['label'] as String? ?? '',
      upperLeague: map['upperLeague'] as String? ?? '',
      lowerLeague: map['lowerLeague'] as String? ?? '',
      standings: standings,
      autoPromoted: parseClubs(map['autoPromoted']),
      autoRelegated: parseClubs(map['autoRelegated']),
    );
  }
}
