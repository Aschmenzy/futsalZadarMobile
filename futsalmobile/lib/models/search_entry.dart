/// A lightweight entry stored in the local search index.
/// Holds just enough data to display a result row and navigate to the detail page.
class SearchEntry {
  final String id;
  final String displayName; // e.g. "Ivan Horvat" or "NK Zadar"
  final String subtitle;    // e.g. club name (player) or league name (club)
  final String type;        // 'player' | 'club'
  final String leagueId;   // e.g. 'liga1'
  final String leagueName; // e.g. 'Liga 1'
  final String? clubId;    // null for clubs (id == clubId), set for players
  final String? imageUrl;  // club logo or player profile picture

  const SearchEntry({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.type,
    required this.leagueId,
    required this.leagueName,
    this.clubId,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'subtitle': subtitle,
    'type': type,
    'leagueId': leagueId,
    'leagueName': leagueName,
    'clubId': clubId,
    'imageUrl': imageUrl,
  };

  factory SearchEntry.fromJson(Map<String, dynamic> map) => SearchEntry(
    id: map['id'] as String,
    displayName: map['displayName'] as String,
    subtitle: map['subtitle'] as String,
    type: map['type'] as String,
    leagueId: map['leagueId'] as String,
    leagueName: map['leagueName'] as String,
    clubId: map['clubId'] as String?,
    imageUrl: map['imageUrl'] as String?,
  );
}
