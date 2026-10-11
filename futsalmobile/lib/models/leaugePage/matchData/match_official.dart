/// Team staff entered on the match sheet (`homeOfficials` / `awayOfficials`).
/// The admin records role, attendance and cards; `name` is usually left empty,
/// in which case the club record's trainer / teamLead supplies it.
class MatchOfficial {
  /// "trainer" or "voditelj".
  final String role;
  final String name;
  final bool present;
  final int yellowCards;
  final int redCards;

  const MatchOfficial({
    required this.role,
    this.name = '',
    this.present = true,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  bool get isTrainer => role == 'trainer';
  bool get isTeamLead => role == 'voditelj';

  Map<String, dynamic> toJson() => {
    'role': role,
    'name': name,
    'present': present,
    'yellowCards': yellowCards,
    'redCards': redCards,
  };

  factory MatchOfficial.fromJson(Map<String, dynamic> map) => MatchOfficial(
    role: map['role']?.toString() ?? '',
    name: map['name']?.toString().trim() ?? '',
    present: map['present'] != false,
    yellowCards: (map['yellowCards'] as num?)?.toInt() ?? 0,
    redCards: (map['redCards'] as num?)?.toInt() ?? 0,
  );

  static List<MatchOfficial> listFrom(dynamic raw) => (raw as List? ?? [])
      .whereType<Map>()
      .map((e) => MatchOfficial.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
