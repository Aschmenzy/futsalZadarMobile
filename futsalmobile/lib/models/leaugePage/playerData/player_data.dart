class PlayerData {
  final String id;
  final String clubName;
  final DateTime dateOfBirth;
  final String firstName;
  final String lastName;
  final DateTime firstRegistrationDate;
  final String idCardNumber;
  final String liga;
  final String perArticle;
  final String season;
  final DateTime thisYearRegistrationDate;
  final String profilePicture;

  const PlayerData({
    required this.id,
    required this.clubName,
    required this.dateOfBirth,
    required this.firstName,
    required this.lastName,
    required this.firstRegistrationDate,
    required this.idCardNumber,
    required this.liga,
    required this.perArticle,
    required this.season,
    required this.thisYearRegistrationDate,
    this.profilePicture = '',
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
    'id': id,
    'clubName': clubName,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'firstName': firstName,
    'lastName': lastName,
    'firstRegistrationDate': firstRegistrationDate.toIso8601String(),
    'idCardNumber': idCardNumber,
    'liga': liga,
    'perArticle': perArticle,
    'season': season,
    'thisYearRegistrationDate': thisYearRegistrationDate.toIso8601String(),
    'profilePicture': profilePicture,
  };

  factory PlayerData.fromJson(Map<String, dynamic> map) => PlayerData(
    id: map['id'] as String,
    clubName: map['clubName'] as String,
    dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
    firstName: map['firstName'] as String,
    lastName: map['lastName'] as String,
    firstRegistrationDate: DateTime.parse(map['firstRegistrationDate'] as String),
    idCardNumber: map['idCardNumber'] as String,
    liga: map['liga'] as String,
    perArticle: map['perArticle'] as String,
    season: map['season'] as String,
    thisYearRegistrationDate: DateTime.parse(map['thisYearRegistrationDate'] as String),
    profilePicture: map['profilePicture'] as String? ?? '',
  );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime(1970);
    if (value is String) {
      final s = value.trim();
      // "dd.MM.yyyy"
      final dotParts = s.split('.');
      if (dotParts.length == 3) {
        try {
          return DateTime(
            int.parse(dotParts[2].trim()),
            int.parse(dotParts[1].trim()),
            int.parse(dotParts[0].trim()),
          );
        } catch (_) {}
      }
      // "dd/MM/yyyy" or "MM/dd/yyyy"
      final slashParts = s.split('/');
      if (slashParts.length == 3) {
        try {
          return DateTime(
            int.parse(slashParts[2].trim()),
            int.parse(slashParts[1].trim()),
            int.parse(slashParts[0].trim()),
          );
        } catch (_) {}
      }
      // ISO 8601 or other standard formats
      return DateTime.tryParse(s) ?? DateTime(1970);
    }
    // Firestore Timestamp
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return DateTime(1970);
    }
  }

  factory PlayerData.fromFirestore(Map<String, dynamic> map, String docId) {
    return PlayerData(
      id: map['id']?.toString() ?? docId,
      clubName: map['clubName']?.toString() ?? '',
      dateOfBirth: _parseDate(map['dateOfBirth']),
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      firstRegistrationDate: _parseDate(map['firstRegistrationDate']),
      idCardNumber: map['idCardNumber']?.toString() ?? '',
      liga: map['liga']?.toString() ?? '',
      perArticle: map['perArticle']?.toString() ?? '',
      season: map['season']?.toString() ?? '',
      thisYearRegistrationDate: _parseDate(map['thisYearRegistrationDate']),
      profilePicture: map['profilePicture']?.toString() ?? '',
    );
  }
}
