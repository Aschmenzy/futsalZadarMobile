import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteItem {
  final String entityId;
  final String type; // 'club' | 'player'
  final String name;
  final String imageUrl;
  final String leagueId;
  final String leagueName;
  final bool starred;
  final bool notificationsEnabled;
  // Club-specific
  final String? season;
  // Player-specific
  final String? clubId;
  final String? clubName;
  final String? clubImageUrl;
  final DateTime createdAt;

  const FavoriteItem({
    required this.entityId,
    required this.type,
    required this.name,
    required this.imageUrl,
    required this.leagueId,
    required this.leagueName,
    required this.starred,
    required this.notificationsEnabled,
    required this.createdAt,
    this.season,
    this.clubId,
    this.clubName,
    this.clubImageUrl,
  });

  Map<String, dynamic> toMap() => {
        'entityId': entityId,
        'type': type,
        'name': name,
        'imageUrl': imageUrl,
        'leagueId': leagueId,
        'leagueName': leagueName,
        'starred': starred,
        'notificationsEnabled': notificationsEnabled,
        'season': season,
        'clubId': clubId,
        'clubName': clubName,
        'clubImageUrl': clubImageUrl,
        'createdAt': createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory FavoriteItem.fromMap(Map<String, dynamic> map) => FavoriteItem(
        entityId: map['entityId'] as String,
        type: map['type'] as String,
        name: map['name'] as String,
        imageUrl: map['imageUrl'] as String? ?? '',
        leagueId: map['leagueId'] as String,
        leagueName: map['leagueName'] as String? ?? '',
        starred: map['starred'] as bool? ?? false,
        notificationsEnabled: map['notificationsEnabled'] as bool? ?? false,
        season: map['season'] as String?,
        clubId: map['clubId'] as String?,
        clubName: map['clubName'] as String?,
        clubImageUrl: map['clubImageUrl'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  FavoriteItem copyWith({bool? starred, bool? notificationsEnabled}) =>
      FavoriteItem(
        entityId: entityId,
        type: type,
        name: name,
        imageUrl: imageUrl,
        leagueId: leagueId,
        leagueName: leagueName,
        starred: starred ?? this.starred,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        createdAt: createdAt,
        season: season,
        clubId: clubId,
        clubName: clubName,
        clubImageUrl: clubImageUrl,
      );
}
