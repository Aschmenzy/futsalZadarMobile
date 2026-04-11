import 'package:futsalmobile/models/search_entry.dart';
import 'package:futsalmobile/services/cache_service.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final _cache = CacheService();
  final _firebase = FirebaseService();

  List<SearchEntry> _index = [];
  bool _indexLoaded = false;

  static const _leagues = ['liga1', 'liga2', 'liga3', 'liga4'];
  static const _leagueNames = {
    'liga1': 'Liga 1',
    'liga2': 'Liga 2',
    'liga3': 'Liga 3',
    'liga4': 'Liga 4',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Call this once (e.g. in main) after Hive is ready.
  /// Loads from cache if valid, otherwise fetches from Firestore.
  Future<void> ensureIndexLoaded(String seasonId) async {
    if (_indexLoaded) return;

    final cacheKey = 'search_index_$seasonId';
    final cached = _cache.getRaw(cacheKey);

    if (cached != null) {
      _index = (cached as List)
          .map((e) => SearchEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _indexLoaded = true;
      return;
    }

    await _buildIndex(seasonId);
  }

  /// Filters the local index by [query]. Returns up to 25 results.
  /// Returns empty list if the index isn't loaded yet or query is blank.
  List<SearchEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || !_indexLoaded) return [];

    return _index
        .where(
          (e) =>
              e.displayName.toLowerCase().contains(q) ||
              e.subtitle.toLowerCase().contains(q),
        )
        .take(25)
        .toList();
  }

  /// Clears in-memory index so next call to [ensureIndexLoaded] rebuilds it.
  void invalidate() {
    _indexLoaded = false;
    _index = [];
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _buildIndex(String seasonId) async {
    final entries = <SearchEntry>[];

    for (final leagueId in _leagues) {
      final leagueName = _leagueNames[leagueId]!;

      // Clubs — getClubsByLeague will write to Hive cache if not already there
      final clubs = await _firebase.getClubsByLeague(leagueId);

      for (final club in clubs) {
        entries.add(
          SearchEntry(
            id: club.id,
            displayName: club.clubName,
            subtitle: leagueName,
            type: 'club',
            leagueId: leagueId,
            leagueName: leagueName,
            clubId: club.id,
            imageUrl: club.clubProfileImg.isNotEmpty
                ? club.clubProfileImg
                : null,
          ),
        );

        // Players — getPlayersByClub will also write to Hive cache
        final players = await _firebase.getPlayersByClub(leagueId, club.id);

        for (final player in players) {
          entries.add(
            SearchEntry(
              id: player.id,
              displayName: player.fullName,
              subtitle: club.clubName,
              type: 'player',
              leagueId: leagueId,
              leagueName: leagueName,
              clubId: club.id,
              imageUrl: player.profilePicture.isNotEmpty
                  ? player.profilePicture
                  : null,
            ),
          );
        }
      }
    }

    // Persist to Hive
    await _cache.setRaw(
      'search_index_$seasonId',
      entries.map((e) => e.toJson()).toList(),
      CacheService.searchIndexTTL,
    );

    _index = entries;
    _indexLoaded = true;
  }
}
