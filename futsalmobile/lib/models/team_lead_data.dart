import 'package:futsalmobile/utils/name_format.dart';
import 'package:futsalmobile/utils/season.dart';

/// A club's voditelj, from `{liga}/{clubId}/voditelji/{id}`. A club can have
/// several. Older clubs only have the plain `teamLead` string on the club
/// record — see [TeamLeadData.fromName].
class TeamLeadData {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePicture;

  /// Seasons the voditelj is not active in (same ids as `config/app.activeSeason`).
  final List<String> inactiveSeasons;

  const TeamLeadData({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture = '',
    this.inactiveSeasons = const [],
  });

  /// Fallback built from the club record's free-text `teamLead`.
  factory TeamLeadData.fromName(String name) =>
      TeamLeadData(id: '', firstName: formatPersonName(name), lastName: '');

  String get fullName => '$firstName $lastName'.trim();

  bool isActiveIn(String? season) => isActiveInSeason(inactiveSeasons, season);

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'profilePicture': profilePicture,
    'inactiveSeasons': inactiveSeasons,
  };

  factory TeamLeadData.fromJson(Map<String, dynamic> map) => TeamLeadData(
    id: map['id']?.toString() ?? '',
    firstName: formatPersonName(map['firstName']?.toString()),
    lastName: formatPersonName(map['lastName']?.toString()),
    profilePicture:
        map['profilePhoto']?.toString() ??
        map['profilePicture']?.toString() ??
        '',
    inactiveSeasons: (map['inactiveSeasons'] as List? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}
