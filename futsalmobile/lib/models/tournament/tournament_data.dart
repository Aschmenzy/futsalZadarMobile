/// A knockout tournament document from the top-level `tournaments` collection.
///
/// Firestore shape:
///   tournaments/{id} — bracketSize, format: "knockout", name, seasonStamp,
///                      status, thirdPlace, isActive
///   subcollections: teams, playerStats, ties
class TournamentData {
  final String id;
  final String name;
  final int bracketSize; // 4, 8, 16, 32 or 64
  final String format;
  final String seasonStamp;
  final String status;
  final bool thirdPlace;

  /// Admin visibility toggle — anything not explicitly `true` must never
  /// surface in the app.
  final bool isActive;

  const TournamentData({
    required this.id,
    required this.name,
    required this.bracketSize,
    required this.format,
    required this.seasonStamp,
    required this.status,
    required this.thirdPlace,
    required this.isActive,
  });

  bool get isInProgress => status == 'in_progress';

  /// Accepts the common variants for a finished tournament until the exact
  /// admin-panel value is confirmed.
  bool get isFinished =>
      status == 'completed' || status == 'finished' || status == 'done';

  factory TournamentData.fromFirestore(String id, Map<String, dynamic> data) {
    return TournamentData(
      id: id,
      name: data['name']?.toString() ?? '',
      bracketSize: (data['bracketSize'] as num?)?.toInt() ?? 0,
      format: data['format']?.toString() ?? 'knockout',
      seasonStamp: data['seasonStamp']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      thirdPlace: data['thirdPlace'] == true,
      isActive: data['isActive'] == true,
    );
  }

  /// Canonical, JSON-safe shape for the Hive cache. Deliberately separate from
  /// [fromFirestore], which tolerates admin-panel field-name variants — the
  /// cache only ever round-trips these already-normalised keys.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bracketSize': bracketSize,
        'format': format,
        'seasonStamp': seasonStamp,
        'status': status,
        'thirdPlace': thirdPlace,
        'isActive': isActive,
      };

  factory TournamentData.fromJson(Map<String, dynamic> json) {
    return TournamentData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bracketSize: (json['bracketSize'] as num?)?.toInt() ?? 0,
      format: json['format']?.toString() ?? 'knockout',
      seasonStamp: json['seasonStamp']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      thirdPlace: json['thirdPlace'] == true,
      isActive: json['isActive'] == true,
    );
  }
}

/// A team entry from tournaments/{id}/teams. Field names are parsed
/// defensively (clubName/name, clubLogo/logo) to match the admin panel.
class TournamentTeam {
  final String id;
  final String name;
  final String logo;

  const TournamentTeam({
    required this.id,
    required this.name,
    required this.logo,
  });

  factory TournamentTeam.fromFirestore(String id, Map<String, dynamic> data) {
    return TournamentTeam(
      id: id,
      name: data['clubName']?.toString() ??
          data['name']?.toString() ??
          data['teamName']?.toString() ??
          '',
      logo: data['clubLogo']?.toString() ?? data['logo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'logo': logo};

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
    );
  }
}

/// A player from tournaments/{id}/teams/{teamId}/players.
class TournamentPlayer {
  final String id;
  final String name;
  final bool isProfessional;

  const TournamentPlayer({
    required this.id,
    required this.name,
    required this.isProfessional,
  });

  factory TournamentPlayer.fromFirestore(String id, Map<String, dynamic> data) {
    final first = data['firstName']?.toString() ?? '';
    final last = data['lastName']?.toString() ?? '';
    final combined = '$first $last'.trim();
    return TournamentPlayer(
      id: id,
      name: combined.isNotEmpty ? combined : (data['name']?.toString() ?? ''),
      isProfessional: data['isProfessional'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isProfessional': isProfessional,
      };

  factory TournamentPlayer.fromJson(Map<String, dynamic> json) {
    return TournamentPlayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isProfessional: json['isProfessional'] == true,
    );
  }
}
