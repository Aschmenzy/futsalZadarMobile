import 'dart:async';

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

  // Fires whenever the index finishes loading (initial load, cache hit, or
  // forced rebuild). Listeners can re-run their search to pick up new players.
  final _indexUpdated = StreamController<void>.broadcast();
  Stream<void> get onIndexUpdated => _indexUpdated.stream;

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
  ///
  /// Pass [forceRefresh: true] after cache invalidation so Firestore's own
  /// disk persistence is bypassed and fresh data is always fetched from server.
  Future<void> ensureIndexLoaded(
    String seasonId, {
    bool forceRefresh = false,
  }) async {
    // _indexLoaded means the in-memory list is populated AND the Hive entry
    // is still valid. If the Hive entry was wiped (e.g. by invalidateByPrefixes)
    // while _indexLoaded is still true, we need to rebuild.
    final cacheKey = 'search_index_$seasonId';
    if (!forceRefresh && _indexLoaded && _cache.isValid(cacheKey)) return;

    if (!forceRefresh) {
      final cached = _cache.getRaw(cacheKey);
      if (cached != null) {
        _index = (cached as List)
            .map(
              (e) => SearchEntry.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _indexLoaded = true;
        _indexUpdated.add(null);
        return;
      }
    }

    await _buildIndex(seasonId, forceRefresh: forceRefresh);
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

  Future<void> _buildIndex(String seasonId, {bool forceRefresh = false}) async {
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

        // Players — forceRefresh bypasses Firestore's own disk cache so newly
        // added players are always included after an admin update.
        final players = await _firebase.getPlayersByClub(
          leagueId,
          club.id,
          forceRefresh: forceRefresh,
        );

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
    _indexUpdated.add(null);
  }
}
