import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:futsalmobile/models/clubStanding.dart';
import 'package:futsalmobile/models/sponsor_data.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';
import 'package:futsalmobile/models/news/news_data.dart';
import 'package:futsalmobile/models/news/news_paginated.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_data.dart';
import 'package:futsalmobile/services/cache_service.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'main',
  );

  final _cache = CacheService();

  // Singleton
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ── Cache invalidation signal ──────────────────────────────────────────────
  // Pages listen to this and re-fetch when the admin bumps lastUpdated.
  final _cacheInvalidated = StreamController<void>.broadcast();
  Stream<void> get onCacheInvalidated => _cacheInvalidated.stream;

  // Maps each Firestore lastUpdated* field → Hive key prefixes to wipe.
  // Only the affected category is cleared, leaving unrelated caches intact.
  static const Map<String, List<String>> _categoryPrefixes = {
    'lastUpdatedMatches': [
      'matches_',
      'standings_',
      'stats_',
      'upcoming_matches_',
    ],
    'lastUpdatedPlayers': ['players_', 'search_index_'],
    'lastUpdatedNews': ['latest_news_'],
    'lastUpdatedSponsors': ['sponsors'],
    'lastUpdatedClubs': ['clubs_', 'search_index_'],
  };

  // True after a cache clear — widgets that mount AFTER the event can still
  // detect that a force-refresh is needed (cleared when they consume it).
  bool _matchCacheDirty = false;
  bool consumeMatchCacheDirty() {
    final dirty = _matchCacheDirty;
    _matchCacheDirty = false;
    return dirty;
  }

  // Real-time listener on config/app — detects admin changes while app is open.
  StreamSubscription? _configWatcher;

  /// Call once after Firebase is initialised. Keeps listening to config/app
  /// for the lifetime of the app and triggers cache clear whenever lastUpdated
  /// advances, even if the user never restarts the app.
  void startConfigWatcher() {
    _configWatcher?.cancel();
    _configWatcher = _db.collection('config').doc('app').snapshots().listen((
      snap,
    ) async {
      if (!snap.exists) return;
      final data = snap.data()!;

      _cachedSeason = data['activeSeason'] as String? ?? _cachedSeason ?? '';
      await _cache.setRaw('season', _cachedSeason, CacheService.seasonTTL);

      bool anyInvalidated = false;
      bool matchesInvalidated = false;

      for (final entry in _categoryPrefixes.entries) {
        final raw = data[entry.key];
        if (raw == null) continue;
        final serverTs = (raw as Timestamp).toDate();
        final localTs = _cache.getLastSyncedAt(category: entry.key);

        if (localTs == null || serverTs.isAfter(localTs)) {
          await _cache.invalidateByPrefixes(entry.value);
          await _cache.setLastSyncedAt(serverTs, category: entry.key);
          anyInvalidated = true;
          if (entry.key == 'lastUpdatedMatches') matchesInvalidated = true;
          debugPrint('[Cache] ${entry.key} advanced → cleared ${entry.value}');
        }
      }

      if (anyInvalidated) {
        if (matchesInvalidated) _matchCacheDirty = true;
        _cacheInvalidated.add(null);
      }
    });
  }

  void stopConfigWatcher() {
    _configWatcher?.cancel();
    _configWatcher = null;
  }

  // ============================================================
  // ACTIVE SEASON
  // ============================================================

  String? _cachedSeason;

  /// Returns the active season, checking Hive cache (24 h TTL) before Firestore.
  Future<String> getActiveSeason({bool forceRefresh = false}) async {
    if (_cachedSeason != null && !forceRefresh) return _cachedSeason!;

    // Check Hive cache
    if (!forceRefresh && _cache.isValid('season')) {
      _cachedSeason = _cache.getRaw('season') as String;
      return _cachedSeason!;
    }

    try {
      final doc = await _db.collection('config').doc('app').get();
      if (!doc.exists) throw Exception('Config dokument ne postoji');

      _cachedSeason = doc.data()?['activeSeason'] ?? '';
      await _cache.setRaw('season', _cachedSeason, CacheService.seasonTTL);
      return _cachedSeason!;
    } catch (e) {
      throw Exception('Greska pri dohvatu aktivne sezone: $e');
    }
  }

  Future<List<String>> getSeasons() async {
    try {
      final snapshot = await _db.collection('seasons').get();
      final seasons = snapshot.docs.map((doc) => doc.id).toList();
      seasons.sort((a, b) => b.compareTo(a));
      return seasons;
    } catch (e) {
      throw Exception('Greska pri dohvatu sezona: $e');
    }
  }

  void clearCache() {
    _cachedSeason = null;
    _cache.clearAll();
  }

  /// Fetches [config/app] from the server and performs selective cache
  /// invalidation: only the categories whose [lastUpdated*] timestamp has
  /// advanced since the last local sync are wiped. Unaffected categories
  /// keep their cached data, reducing unnecessary Firestore reads.
  ///
  /// Returns [true] if at least one category was invalidated.
  Future<bool> checkForUpdates() async {
    try {
      final doc = await _db
          .collection('config')
          .doc('app')
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) return false;
      final data = doc.data()!;

      _cachedSeason = data['activeSeason'] as String? ?? _cachedSeason ?? '';
      await _cache.setRaw('season', _cachedSeason, CacheService.seasonTTL);

      bool anyInvalidated = false;

      for (final entry in _categoryPrefixes.entries) {
        final raw = data[entry.key];
        if (raw == null) continue;
        final serverTs = (raw as Timestamp).toDate();
        final localTs = _cache.getLastSyncedAt(category: entry.key);

        if (localTs == null || serverTs.isAfter(localTs)) {
          await _cache.invalidateByPrefixes(entry.value);
          await _cache.setLastSyncedAt(serverTs, category: entry.key);
          anyInvalidated = true;
          debugPrint(
            '[Cache] checkForUpdates: ${entry.key} advanced → cleared ${entry.value}',
          );
        }
      }

      return anyInvalidated;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CLUBS
  // ============================================================

  /// Fetches clubs for [leagueId], using Hive cache (7-day TTL).
  Future<List<ClubData>> getClubsByLeague(String leagueId) async {
    final key = 'clubs_$leagueId';

    final cached = _cache.getRaw(key);
    if (cached != null) {
      return (cached as List)
          .map((e) => ClubData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    try {
      final snapshot = await _db.collection(leagueId).get();
      final clubs = snapshot.docs
          .map((doc) => ClubData.fromFirestore(doc.data(), doc.id))
          .toList();

      await _cache.setRaw(
        key,
        clubs.map((c) => c.toJson()).toList(),
        CacheService.clubsTTL,
      );

      return clubs;
    } catch (e) {
      throw Exception('Greska pri dohvatu klubova: $e');
    }
  }

  /// Fetches a single club by ID. Tries the league cache first.
  Future<ClubData?> getClubById(String leagueId, String clubId) async {
    // Try to find it in the already-cached league list first
    if (_cache.isValid('clubs_$leagueId')) {
      final clubs = await getClubsByLeague(leagueId);
      try {
        return clubs.firstWhere((c) => c.id == clubId);
      } catch (_) {}
    }

    try {
      final doc = await _db.collection(leagueId).doc(clubId).get();
      if (!doc.exists) return null;
      return ClubData.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Greska pri dohvatu kluba: $e');
    }
  }

  Future<int> getClubCount(String leagueId) async {
    try {
      final snapshot = await _db.collection(leagueId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Greska pri dohvatu broja klubova: $e');
    }
  }

  Future<MatchData?> getNextMatchByClub(
    String leagueCode,
    String? homeClub,
  ) async {
    if (homeClub == null) return null;

    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final baseQuery = _db
          .collection('seasons')
          .doc(_cachedSeason)
          .collection('leagues')
          .doc(leagueCode)
          .collection('matches')
          .where('status', isEqualTo: 'scheduled')
          .where('matchDate', isGreaterThanOrEqualTo: todayStr)
          .orderBy('matchDate', descending: false)
          .orderBy('matchTime')
          .limit(1);

      final results = await Future.wait([
        baseQuery.where('homeTeam', isEqualTo: homeClub).get(),
        baseQuery.where('awayTeam', isEqualTo: homeClub).get(),
      ]);

      final allDocs = [...results[0].docs, ...results[1].docs];
      if (allDocs.isEmpty) return null;

      allDocs.sort(
        (a, b) => (a.data()['matchDate'] as String).compareTo(
          b.data()['matchDate'] as String,
        ),
      );

      final doc = allDocs.first;
      return MatchData.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Greska pri dohvatu sljedece utakmice: $e');
    }
  }

  // ============================================================
  // PLAYERS
  // ============================================================

  /// Fetches players for one club, using Hive cache (24-hour TTL).
  ///
  /// Pass [forceRefresh: true] to bypass both Hive and Firestore's own disk
  /// cache and always fetch directly from the server. Required after cache
  /// invalidation so Firestore's persistence layer doesn't return stale data.
  Future<List<PlayerData>> getPlayersByClub(
    String leagueId,
    String clubId, {
    bool forceRefresh = false,
  }) async {
    final key = 'players_${leagueId}_$clubId';

    if (!forceRefresh) {
      final cached = _cache.getRaw(key);
      if (cached != null) {
        return (cached as List)
            .map(
              (e) => PlayerData.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
    }

    try {
      final snapshot = await _db
          .collection(leagueId)
          .doc(clubId)
          .collection('players')
          .get(
            forceRefresh
                ? const GetOptions(source: Source.server)
                : const GetOptions(source: Source.serverAndCache),
          );

      final players = snapshot.docs
          .map((doc) => PlayerData.fromFirestore(doc.data(), doc.id))
          .toList();

      await _cache.setRaw(
        key,
        players.map((p) => p.toJson()).toList(),
        CacheService.playersTTL,
      );

      return players;
    } catch (e) {
      throw Exception('Greska pri dohvatu igraca: $e');
    }
  }

  Future<ClubData> getClubWithPlayers(String leagueId, String clubId) async {
    final club = await getClubById(leagueId, clubId);
    if (club == null) throw Exception('Klub $clubId ne postoji u $leagueId');
    final players = await getPlayersByClub(leagueId, clubId);
    return club.copyWithPlayers(players);
  }

  Future<List<ClubData>> getLeagueWithAllPlayers(String leagueId) async {
    final clubs = await getClubsByLeague(leagueId);
    return Future.wait(
      clubs.map((club) async {
        final players = await getPlayersByClub(leagueId, club.id);
        return club.copyWithPlayers(players);
      }),
    );
  }

  Future<int> getCurrentRound(String leagueCode, {String? season}) async {
    try {
      final seasonId = (season != null && season.isNotEmpty)
          ? season
          : _cachedSeason;
      final snapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('leagues')
          .doc(leagueCode)
          .collection('matches')
          .where('status', isEqualTo: 'scheduled')
          .orderBy('round', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 0;
      return (snapshot.docs.first.data()['round'] as int?) ?? 0;
    } catch (e) {
      throw Exception('Greska pri dohvatu runde: $e');
    }
  }

  Future<MatchData?> getNextMatch(String leagueCode, {String? season}) async {
    try {
      final seasonId = (season != null && season.isNotEmpty)
          ? season
          : _cachedSeason;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final snapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('leagues')
          .doc(leagueCode)
          .collection('matches')
          .where('status', isEqualTo: 'scheduled')
          .where('matchDate', isGreaterThanOrEqualTo: todayStr)
          .orderBy('matchDate', descending: false)
          .orderBy('matchTime')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      debugPrint('${doc.data()}');
      return MatchData.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Greska pri dohvatu sljedece utakmice: $e');
    }
  }

  // ============================================================
  // MATCHES
  // ============================================================

  /// Fetches all matches for a league, using Hive cache (30-minute TTL).
  ///
  /// Pass [forceRefresh: true] to bypass both Hive and Firestore disk cache
  /// and always fetch directly from the server. Used after cache invalidation.
  Future<List<MatchData>> getAllMatches(
    String leagueCode, {
    String? season,
    bool forceRefresh = false,
  }) async {
    final seasonId = (season != null && season.isNotEmpty)
        ? season
        : _cachedSeason!;
    final key = 'matches_${leagueCode}_$seasonId';

    if (!forceRefresh) {
      final cached = _cache.getRaw(key);
      if (cached != null) {
        return (cached as List)
            .map((e) => MatchData.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    try {
      // Source.server bypasses Firestore's own disk cache — guarantees we see
      // any match the admin just added, even if Firestore cached the old list.
      final snapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('leagues')
          .doc(leagueCode)
          .collection('matches')
          .orderBy('matchDate', descending: true)
          .orderBy('matchTime')
          .get(const GetOptions(source: Source.server));

      final matches = snapshot.docs
          .map((doc) => MatchData.fromFirestore(doc.data(), doc.id))
          .toList();

      await _cache.setRaw(
        key,
        matches.map((m) => m.toJson()).toList(),
        CacheService.matchesTTL,
      );

      return matches;
    } catch (e) {
      // If server fetch fails (offline), fall back to Firestore disk cache
      try {
        final snapshot = await _db
            .collection('seasons')
            .doc(seasonId)
            .collection('leagues')
            .doc(leagueCode)
            .collection('matches')
            .orderBy('matchDate', descending: true)
            .orderBy('matchTime')
            .get(const GetOptions(source: Source.cache));

        return snapshot.docs
            .map((doc) => MatchData.fromFirestore(doc.data(), doc.id))
            .toList();
      } catch (_) {
        throw Exception('Greska pri dohvatu utakmica: $e');
      }
    }
  }

  Future<MatchData?> getClosestUpcomingMatch({
    DateTime? targetDate,
    String? season,
  }) async {
    try {
      final seasonId = (season != null && season.isNotEmpty)
          ? season
          : _cachedSeason;
      targetDate ??= DateTime.now();

      final leaguesSnapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('leagues')
          .get();

      final List<MatchData> allMatches = [];

      for (final leagueDoc in leaguesSnapshot.docs) {
        final matchesSnapshot = await leagueDoc.reference
            .collection('matches')
            .where('matchDate', isGreaterThanOrEqualTo: targetDate)
            .orderBy('matchDate')
            .limit(1)
            .get();

        for (final matchDoc in matchesSnapshot.docs) {
          allMatches.add(MatchData.fromFirestore(matchDoc.data(), matchDoc.id));
        }
      }

      if (allMatches.isNotEmpty) {
        allMatches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
        return allMatches.first;
      }

      final playoffsSnapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('playoffs')
          .get();

      final List<MatchData> playoffMatches = [];

      for (final playoffDoc in playoffsSnapshot.docs) {
        final matchesSnapshot = await playoffDoc.reference
            .collection('matches')
            .where('matchDate', isGreaterThanOrEqualTo: targetDate)
            .orderBy('matchDate')
            .limit(1)
            .get();

        for (final matchDoc in matchesSnapshot.docs) {
          playoffMatches.add(
            MatchData.fromFirestore(matchDoc.data(), matchDoc.id),
          );
        }
      }

      if (playoffMatches.isNotEmpty) {
        playoffMatches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
        return playoffMatches.first;
      }

      return null;
    } catch (e) {
      throw Exception('Greska pri dohvatu najblize utakmice: $e');
    }
  }

  // ── Single match real-time stream ─────────────────────────────────────────

  /// Listens to a single match document and emits every time it changes.
  /// Used by [MatchDetailsPage] so scores and events update live.
  Stream<MatchData> watchMatch(MatchData match) {
    final seasonId = match.season.isNotEmpty
        ? match.season
        : (_cachedSeason ?? '');
    return _db
        .collection('seasons')
        .doc(seasonId)
        .collection('leagues')
        .doc(match.leagueCode)
        .collection('matches')
        .doc(match.matchId)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => MatchData.fromFirestore(snap.data()!, snap.id));
  }

  // ── Upcoming matches stream ────────────────────────────────────────────────

  BehaviorSubject<List<MatchData>>? _matchesSubject;
  StreamSubscription? _matchesListener;

  /// Returns a stream of upcoming matches that updates in real time.
  ///
  /// Firestore's [snapshots()] fires only when an actual document in the
  /// result set changes — no polling, no unnecessary reads. The Hive cache
  /// is updated on each emission so the UI can show data instantly on the
  /// next mount without waiting for Firestore.
  Stream<List<MatchData>> getUpcomingMatchesStream({
    DateTime? targetDate,
    String? season,
  }) {
    if (_matchesSubject != null && !_matchesSubject!.isClosed) {
      return _matchesSubject!.stream;
    }

    final seasonId = (season != null && season.isNotEmpty)
        ? season
        : _cachedSeason!;
    targetDate ??= DateTime.now();
    final dateString =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    _matchesSubject = BehaviorSubject<List<MatchData>>();

    // Serve Hive cache immediately so the UI has data before Firestore responds.
    final cachedKey = 'upcoming_matches_$seasonId';
    final cachedRaw = _cache.getRaw(cachedKey);
    if (cachedRaw != null) {
      _matchesSubject!.add(
        (cachedRaw as List)
            .map((e) => MatchData.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }

    // Real-time listener — Firestore pushes a new snapshot only when a
    // matching document is created, updated, or deleted.
    _matchesListener = _db
        .collectionGroup('matches')
        .where('season', isEqualTo: seasonId)
        .where('matchDate', isGreaterThanOrEqualTo: dateString)
        .orderBy('matchDate')
        .snapshots()
        .listen(
          (snapshot) async {
            final matches =
                snapshot.docs
                    .map((doc) => MatchData.fromFirestore(doc.data(), doc.id))
                    .toList()
                  ..sort((a, b) => a.matchDate.compareTo(b.matchDate));

            await _cache.setRaw(
              cachedKey,
              matches.map((m) => m.toJson()).toList(),
              CacheService.upcomingMatchesTTL,
            );

            if (_matchesSubject != null && !_matchesSubject!.isClosed) {
              _matchesSubject!.add(matches);
            }
          },
          onError: (Object error) {
            if (_matchesSubject != null && !_matchesSubject!.isClosed) {
              _matchesSubject!.addError(error);
            }
          },
        );

    return _matchesSubject!.stream;
  }

  void disposeMatchesStream() {
    _matchesListener?.cancel();
    _matchesListener = null;
    _matchesSubject?.close();
    _matchesSubject = null;
  }

  Future<List<MatchData>> getUpcomingMatches(
    String seasonId,
    String dateString,
  ) async {
    try {
      final allMatchesSnapshot = await _db
          .collectionGroup('matches')
          .where('season', isEqualTo: seasonId)
          .where('matchDate', isGreaterThanOrEqualTo: dateString)
          .orderBy('matchDate')
          .get();

      final allMatches = allMatchesSnapshot.docs.map((doc) {
        return MatchData.fromFirestore(doc.data(), doc.id);
      }).toList();

      allMatches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return allMatches;
    } catch (e) {
      throw Exception('Greška pri dohvatu utakmica: $e');
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Future<PlayerStatsData?> getPlayerStatsByPlayerId(
    String leagueCode,
    String playerId, {
    String? season,
  }) async {
    try {
      final seasonId = (season != null && season.isNotEmpty)
          ? season
          : _cachedSeason;
      final snapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('leagues')
          .doc(leagueCode)
          .collection('playerStats')
          .where('odFCplayerId', isEqualTo: playerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return PlayerStatsData.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Greska pri dohvatu statistika igraca: $e');
    }
  }

  /// Fetches all league player stats, using Hive cache (1-hour TTL).
  /// The raw list is cached; sorting happens locally on every call (negligible).
  Future<Map<String, List<PlayerStatsData>>> getAllLeaguePlayerStats(
    String leagueCode, {
    String? season,
  }) async {
    final seasonId = (season != null && season.isNotEmpty)
        ? season
        : _cachedSeason!;
    final key = 'stats_${leagueCode}_$seasonId';

    List<PlayerStatsData> players;

    final cached = _cache.getRaw(key);
    if (cached != null) {
      players = (cached as List)
          .map(
            (e) =>
                PlayerStatsData.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } else {
      try {
        final snapshot = await _db
            .collection('seasons')
            .doc(seasonId)
            .collection('leagues')
            .doc(leagueCode)
            .collection('playerStats')
            .get();

        if (snapshot.docs.isEmpty) {
          return {
            'topScorers': [],
            'topRedCards': [],
            'topYellowCards': [],
            'oneYellow': [],
            'twoYellows': [],
          };
        }

        players = snapshot.docs
            .map((doc) => PlayerStatsData.fromFirestore(doc.data(), doc.id))
            .toList();

        await _cache.setRaw(
          key,
          players.map((p) => p.toJson()).toList(),
          CacheService.statsTTL,
        );
      } catch (e) {
        throw Exception('Greska pri dohvatu statistika igraca: $e');
      }
    }

    // Sort locally (fast, no Firestore reads)
    final scorers = [...players]
      ..sort(
        (a, b) => (b.goals + b.goals10m + b.goals6m).compareTo(
          a.goals + a.goals10m + a.goals6m,
        ),
      );

    final redCards = [...players]
      ..sort((a, b) => b.redCards.compareTo(a.redCards));

    final yellowCards = [...players]
      ..sort((a, b) => b.yellowCards.compareTo(a.yellowCards));

    final activeYellowPlayers = players
        .where((p) => p.activeYellows > 0)
        .toList();

    return {
      'topScorers': scorers.take(5).toList(),
      'topRedCards': redCards.take(5).toList(),
      'topYellowCards': yellowCards.take(5).toList(),
      'oneYellow': activeYellowPlayers
          .where((p) => p.activeYellows == 1)
          .take(5)
          .toList(),
      'twoYellows': activeYellowPlayers
          .where((p) => p.activeYellows == 2)
          .take(5)
          .toList(),
    };
  }

  Future<ClubStanding?> getBestClubInLeague(String leagueCode) async {
    try {
      final snapshot = await _db
          .collection('seasons')
          .doc(_cachedSeason)
          .collection('leagues')
          .doc(leagueCode)
          .collection('standings')
          .orderBy('points', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return ClubStanding.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Greska pri pronalasku najboljeg tima u lizi: $e');
    }
  }

  // ============================================================
  // STANDINGS
  // ============================================================

  /// Fetches league standings, using Hive cache (1-hour TTL).
  Future<List<ClubStanding>> getAllClubsInLeague(
    String leagueCode, {
    String? season,
  }) async {
    final seasonId = (season != null && season.isNotEmpty)
        ? season
        : _cachedSeason!;
    final key = 'standings_${leagueCode}_$seasonId';

    final cached = _cache.getRaw(key);
    if (cached != null) {
      return (cached as List)
          .map(
            (e) => ClubStanding.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    try {
      final snapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('leagues')
          .doc(leagueCode)
          .collection('standings')
          .orderBy('points', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final standings = snapshot.docs
          .map((doc) => ClubStanding.fromFirestore(doc.data(), doc.id))
          .toList();

      await _cache.setRaw(
        key,
        standings.map((s) => s.toJson()).toList(),
        CacheService.standingsTTL,
      );

      return standings;
    } catch (e) {
      throw Exception('Greška pri dohvaćanju klubova u ligi: $e');
    }
  }

  Future<Map<String, List<MatchData>>> getLastFiveMatchScores(
    String leagueCode, {
    String? season,
  }) async {
    try {
      final seasonId = (season != null && season.isNotEmpty)
          ? season
          : _cachedSeason;

      final standingsSnapshot = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('leagues')
          .doc(leagueCode)
          .collection('standings')
          .orderBy('points', descending: true)
          .get();

      if (standingsSnapshot.docs.isEmpty) return {};

      // Reuse cached getAllMatches to avoid an extra Firestore read
      final allMatches = await getAllMatches(leagueCode, season: seasonId);

      final Map<String, List<MatchData>> result = {};

      for (final standingDoc in standingsSnapshot.docs) {
        final clubName = standingDoc.data()['clubName'] as String?;
        if (clubName == null) continue;

        result[clubName] = allMatches
            .where((m) => m.homeTeam == clubName || m.awayTeam == clubName)
            .take(5)
            .toList();
      }

      return result;
    } catch (e) {
      throw Exception('Greška pri dohvaćanju zadnjih meceva za svaki klub: $e');
    }
  }

  // ============================================================
  // NEWS
  // ============================================================

  Future<NewsPaginated> getNewsPaginated({
    int limit = 5,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _db
          .collection('seasons')
          .doc(_cachedSeason)
          .collection('news')
          .orderBy('createdAt', descending: true)
          .where('isActive', isEqualTo: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final items = snapshot.docs
          .map(
            (doc) => NewsData.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      return NewsPaginated(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      throw Exception('Greska pri dohvatu vijesti: $e');
    }
  }

  /// Returns the latest news article, using Hive cache (30-minute TTL).
  Future<NewsData?> getLatestNews() async {
    final key = 'latest_news_$_cachedSeason';

    final cached = _cache.getRaw(key);
    if (cached != null) {
      return NewsData.fromJson(Map<String, dynamic>.from(cached as Map));
    }

    try {
      final snapshot = await _db
          .collection('seasons')
          .doc(_cachedSeason)
          .collection('news')
          .orderBy('createdAt', descending: true)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final news = NewsData.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
      await _cache.setRaw(key, news.toJson(), CacheService.newsTTL);
      return news;
    } catch (e) {
      throw Exception('Greska pri dohvatu vijesti: $e');
    }
  }

  // ============================================================
  // SPONSORS
  // ============================================================

  /// Fetches active sponsors ordered by [order], cached for 24 h.
  /// Cleared automatically when the admin bumps [lastUpdated].
  Future<List<SponsorData>> getSponsors() async {
    const key = 'sponsors';

    final cached = _cache.getRaw(key);
    if (cached != null) {
      return (cached as List)
          .map((e) => SponsorData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    try {
      final snapshot = await _db.collection('sponsors').get();

      final sponsors =
          snapshot.docs
              .map((doc) => SponsorData.fromFirestore(doc.data(), doc.id))
              .where((s) => s.isActive)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

      await _cache.setRaw(
        key,
        sponsors.map((s) => s.toJson()).toList(),
        CacheService.sponsorsTTL,
      );

      return sponsors;
    } catch (e) {
      throw Exception('Greška pri dohvatu sponzora: $e');
    }
  }
}
