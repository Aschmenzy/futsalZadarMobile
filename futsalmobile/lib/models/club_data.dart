import 'leaugePage/playerData/player_data.dart';

class ClubData {
  final String id;
  final String clubName;
  final String clubProfileImg;
  final String contact;
  final String contactPerson;
  final DateTime createdAt;
  final String dresDomaci;
  final String dresGostujuci;
  final String email;
  final String teamLead;
  final String trainer;
  final List<PlayerData> players;

  const ClubData({
    required this.id,
    required this.clubName,
    required this.clubProfileImg,
    required this.contact,
    required this.contactPerson,
    required this.createdAt,
    required this.dresDomaci,
    required this.dresGostujuci,
    required this.email,
    required this.teamLead,
    required this.trainer,
    this.players = const [],
  });

  factory ClubData.fromFirestore(Map<String, dynamic> map, String docId) {
    return ClubData(
      id: docId,
      clubName: map['clubName'] ?? '',
      clubProfileImg: map['clubProfileImg'] ?? '',
      contact: map['contact'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      dresDomaci: map['dresDomaci'] ?? '',
      dresGostujuci: map['dresGostujuci'] ?? '',
      email: map['email'] ?? '',
      teamLead: map['teamLead'] ?? '',
      trainer: map['trainer'] ?? '',
      players: [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clubName': clubName,
    'clubProfileImg': clubProfileImg,
    'contact': contact,
    'contactPerson': contactPerson,
    'createdAt': createdAt.toIso8601String(),
    'dresDomaci': dresDomaci,
    'dresGostujuci': dresGostujuci,
    'email': email,
    'teamLead': teamLead,
    'trainer': trainer,
  };

  factory ClubData.fromJson(Map<String, dynamic> map) => ClubData(
    id: map['id'] as String,
    clubName: map['clubName'] as String,
    clubProfileImg: map['clubProfileImg'] as String,
    contact: map['contact'] as String,
    contactPerson: map['contactPerson'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    dresDomaci: map['dresDomaci'] as String,
    dresGostujuci: map['dresGostujuci'] as String,
    email: map['email'] as String,
    teamLead: map['teamLead'] as String,
    trainer: map['trainer'] as String,
  );

  /// Returns a copy with players populated
  ClubData copyWithPlayers(List<PlayerData> players) {
    return ClubData(
      id: id,
      clubName: clubName,
      clubProfileImg: clubProfileImg,
      contact: contact,
      contactPerson: contactPerson,
      createdAt: createdAt,
      dresDomaci: dresDomaci,
      dresGostujuci: dresGostujuci,
      email: email,
      teamLead: teamLead,
      trainer: trainer,
      players: players,
    );
  }
}
