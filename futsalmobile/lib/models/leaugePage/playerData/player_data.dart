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
  });

  String get fullName => '$firstName $lastName';

  factory PlayerData.fromFirestore(Map<String, dynamic> map, String docId) {
    return PlayerData(
      id: map['id'] ?? docId,
      clubName: map['clubName'] ?? '',
      dateOfBirth: (map['dateOfBirth'] as dynamic).toDate(),
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      firstRegistrationDate: (map['firstRegistrationDate'] as dynamic).toDate(),
      idCardNumber: map['idCardNumber'] ?? '',
      liga: map['liga'] ?? '',
      perArticle: map['perArticle'] ?? '',
      season: map['season'] ?? '',
      thisYearRegistrationDate: (map['thisYearRegistrationDate'] as dynamic)
          .toDate(),
    );
  }
}
