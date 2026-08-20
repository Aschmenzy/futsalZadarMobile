import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:futsalmobile/models/clubStanding.dart';
import 'package:futsalmobile/models/playoff_group_data.dart';
import 'package:futsalmobile/models/playoff_info.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/models/sponsor_data.dart';
import 'package:futsalmobile/models/tournament/tournament_data.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';
import 'package:futsalmobile/models/news/news_data.dart';
import 'package:futsalmobile/models/news/news_paginated.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_data.dart';
import 'package:futsalmobile/services/cache_service.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

final String? kApiBaseUrl = dotenv.env['API_BASE_URL'];
// ──────────────────────────────────────────────────────────────────────────

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
  final _cacheInvalidated = StreamController<void>.broadcast();
  Stream<void> get onCacheInvalidated => _cacheInvalidated.stream;

  /// Fires only when `lastUpdatedTournaments` advances. Pages showing a live
  /// bracket listen here instead of [onCacheInvalidated] so a news or matches
  /// bump doesn't cost them a round trip to Firestore.
  final _tournamentsInvalidated = StreamController<void>.broadcast();
  Stream<void> get onTournamentsInvalidated => _tournamentsInvalidated.stream;

  static const Map<String, List<String>> _categoryPrefixes = {
    'lastUpdatedMatches': [
      'matches_',
      'standings_',
      'stats_',
      'upcoming_matches_',
    ],
    'lastUpdatedPlayers': ['players_', 'search_index_'],
    'lastUpdatedNews': ['latest_news_', 'news_all'],
    'lastUpdatedSponsors': ['sponsors'],
    'lastUpdatedClubs': ['clubs_', 'search_index_'],
    // Playoff structure lives in Firestore, not Hive — empty prefix list, but
    // the timestamp is still tracked so we know when to re-run checkPlayoffs().
    'lastUpdatedPlayoff': [],
    // Every tournament cache key starts with 'tournaments_' (list, ties, teams
    // and per-team players), so one prefix clears the whole section.
    'lastUpdatedTournaments': ['tournaments_'],
  };

  bool _matchCacheDirty = false;
  bool consumeMatchCacheDirty() {
    final dirty = _matchCacheDirty;
    _matchCacheDirty = false;
    return dirty;
  }

  bool _playoffCacheDirty = false;
  bool consumePlayoffCacheDirty() {
    final dirty = _playoffCacheDirty;
    _playoffCacheDirty = false;
    return dirty;
  }

  bool _tournamentsCacheDirty = false;
  bool consumeTournamentsCacheDirty() {
    final dirty = _tournamentsCacheDirty;
    _tournamentsCacheDirty = false;
    return dirty;
  }

  StreamSubscription? _configWatcher;

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
      bool playoffInvalidated = false;
      bool tournamentsInvalidated = false;

      for (final entry in _categoryPrefixes.entries) {
        final raw = data[entry.key];
        // Skip anything that isn't a real Timestamp — a field the admin panel
        // wrote as a string or number must not abort the whole loop and leave
        // the remaining categories unprocessed.
        if (raw is! Timestamp) continue;
        final serverTs = raw.toDate();
        final localTs = _cache.getLastSyncedAt(category: entry.key);

        if (localTs == null || serverTs.isAfter(localTs)) {
          await _cache.invalidateByPrefixes(entry.value);
          await _cache.setLastSyncedAt(serverTs, category: entry.key);
          anyInvalidated = true;
          if (entry.key == 'lastUpdatedMatches') matchesInvalidated = true;
          if (entry.key == 'lastUpdatedPlayoff') playoffInvalidated = true;
          if (entry.key == 'lastUpdatedTournaments') {
            tournamentsInvalidated = true;
          }
          debugPrint('[Cache] ${entry.key} advanced → cleared ${entry.value}');
        }
      }

      if (playoffInvalidated) {
        await checkPlayoffs();
      }

      if (anyInvalidated) {
        if (matchesInvalidated) _matchCacheDirty = true;
        if (playoffInvalidated) _playoffCacheDirty = true;
        if (tournamentsInvalidated) {
          _tournamentsCacheDirty = true;
          // Broadcast rather than a one-shot flag: several tournament pages
          // can be open at once (list, bracket, teams) and each needs the
          // signal, unlike [_tournamentsCacheDirty] which LeaguePage consumes.
          _tournamentsInvalidated.add(null);
        }
        _cacheInvalidated.add(null);
      }
    });
  }

  void stopConfigWatcher() {
    _configWatcher?.cancel();
    _configWatcher = null;
  }

  // ── Match detail ──────────────────────────────────────────────────────────

  Future<MatchData> getMatchDetail(String matchId) async {
    final data = await _getMap('/api/public/matches/$matchId');
    return MatchData.fromJson(
      Map<String, dynamic>.from(data['match'] as Map),
    );
  }

  // ── HTTP helper ────────────────────────────────────────────────────────────

  /// GET with retry: transient socket drops ("Software caused connection
  /// abort" on Android when the network switches or the app resumes) and
  /// timeouts get two extra attempts with a short backoff.
  Future<http.Response> _getWithRetry(String path) async {
    const maxAttempts = 3;
    for (var attempt = 1; ; attempt++) {
      try {
        return await http
            .get(Uri.parse('$kApiBaseUrl$path'))
            .timeout(const Duration(seconds: 60));
      } on http.ClientException {
        if (attempt == maxAttempts) rethrow;
      } on TimeoutException {
        if (attempt == maxAttempts) rethrow;
      }
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _getWithRetry(path);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('API $path returned ${response.statusCode}');
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await _getWithRetry(path);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('API $path returned ${response.statusCode}');
  }

  // ============================================================
  // ACTIVE SEASON
  // ============================================================

  String? _cachedSeason;

  Future<String> getActiveSeason({bool forceRefresh = false}) async {
    if (_cachedSeason != null && !forceRefresh) return _cachedSeason!;
    if (!forceRefresh && _cache.isValid('season')) {
      _cachedSeason = _cache.getRaw('season') as String;
      return _cachedSeason!;
    }
    try {
      final snap = await _db.collection('config').doc('app').get();
      if (!snap.exists) throw Exception('Config dokument ne postoji');
      _cachedSeason = snap.data()?['activeSeason'] ?? '';
      await _cache.setRaw('season', _cachedSeason, CacheService.seasonTTL);
      return _cachedSeason!;
    } catch (e) {
      // Fall back to stale Hive entry (ignores TTL) rather than crashing.
      final stale = _cache.getRawStale('season');
      if (stale != null) {
        _cachedSeason = stale as String;
        return _cachedSeason!;
      }
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

  Future<bool> checkForUpdates() async {
    try {
      final snap = await _db
          .collection('config')
          .doc('app')
          .get(const GetOptions(source: Source.cache));
      if (!snap.exists) return false;
      final data = snap.data()!;

      _cachedSeason = data['activeSeason'] as String? ?? _cachedSeason ?? '';
      await _cache.setRaw('season', _cachedSeason, CacheService.seasonTTL);

      bool anyInvalidated = false;
      for (final entry in _categoryPrefixes.entries) {
        final raw = data[entry.key];
        // See startConfigWatcher(): a non-Timestamp field is skipped rather
        // than thrown on, so one bad field can't disable cold-start
        // invalidation for every other category.
        if (raw is! Timestamp) continue;
        final serverTs = raw.toDate();
        final localTs = _cache.getLastSyncedAt(category: entry.key);
        if (localTs == null || serverTs.isAfter(localTs)) {
          await _cache.invalidateByPrefixes(entry.value);
          await _cache.setLastSyncedAt(serverTs, category: entry.key);
          anyInvalidated = true;
          if (entry.key == 'lastUpdatedPlayoff') {
            // Reset in-memory playoff info so the checkPlayoffs() call in
            // main() re-fetches fresh data from Firestore on this cold start.
            _cachedPlayoffInfo = const PlayoffInfo(hasLiga1: false, ligaskaGroups: []);
          }
        }
      }
      return anyInvalidated;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CLUBS  — served from /api/public/clubs
  // ============================================================

  // Internal: load all clubs from API, cache as 'clubs_all'.
  Future<Map<String, List<ClubData>>> _loadAllClubs() async {
    const cacheKey = 'clubs_all';

    final cached = _cache.getRaw(cacheKey);
    if (cached != null) {
      final raw = cached as Map;
      return raw.map(
        (league, list) => MapEntry(
          league as String,
          (list as List)
              .map(
                (e) => ClubData.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
        ),
      );
    }

    final data = await _getMap('/api/public/clubs');
    final result = data.map(
      (league, list) => MapEntry(
        league,
        (list as List)
            .map((e) => ClubData.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      ),
    );

    await _cache.setRaw(
      cacheKey,
      data, // already JSON-serialisable
      CacheService.clubsTTL,
    );

    return result;
  }

  Future<List<ClubData>> getClubsByLeague(String leagueId) async {
    try {
      final all = await _loadAllClubs();
      return all[leagueId] ?? [];
    } catch (e) {
      throw Exception('Greska pri dohvatu klubova: $e');
    }
  }

  Future<ClubData?> getClubById(String leagueId, String clubId) async {
    try {
      final clubs = await getClubsByLeague(leagueId);
      try {
        return clubs.firstWhere((c) => c.id == clubId);
      } catch (_) {
        return null;
      }
    } catch (e) {
      throw Exception('Greska pri dohvatu kluba: $e');
    }
  }

  Future<int> getClubCount(String leagueId) async {
    final clubs = await getClubsByLeague(leagueId);
    return clubs.length;
  }

  // ============================================================
  // PLAYERS  — served from /api/public/players
  // ============================================================

  // Internal: load all players from API, cache as 'players_all'.
  Future<List<Map<String, dynamic>>> _loadAllPlayers() async {
    const cacheKey = 'players_all';

    final cached = _cache.getRaw(cacheKey);
    if (cached != null) {
      return (cached as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    final list = await _getList('/api/public/players');
    final players = list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    await _cache.setRaw(cacheKey, list, CacheService.playersTTL);
    return players;
  }

  Future<List<PlayerData>> getPlayersByClub(
    String leagueId,
    String clubId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) await _cache.invalidate('players_all');

      final all = await _loadAllPlayers();
      return all
          .where((p) => p['_league'] == leagueId && p['_clubId'] == clubId)
          .map((e) => PlayerData.fromJson(e))
          .toList();
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

  // ============================================================
  // MATCHES  — served from /api/public/matches
  // ============================================================

  // Internal: load all matches from API for a season.
  Future<Map<String, List<MatchData>>> _loadAllMatches({String? season}) async {
    final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
    final cacheKey = 'matches_all_$seasonId';

    final cached = _cache.getRaw(cacheKey);
    if (cached != null) {
      final raw = cached as Map;
      // Check if cached data already has leagueCode injected.
      bool hasLeagueCode = false;
      if (raw.isNotEmpty) {
        final firstList = raw[raw.keys.first] as List? ?? [];
        if (firstList.isNotEmpty) {
          final m = firstList.first as Map?;
          final lc = m?['leagueCode'];
          hasLeagueCode = lc != null && lc.toString().isNotEmpty;
        }
      }

      if (hasLeagueCode) {
        return raw.map(
          (league, list) => MapEntry(
            league as String,
            (list as List)
                .map(
                  (e) =>
                      MatchData.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList(),
          ),
        );
      }
      // Stale cache without leagueCode — fall through to re-fetch.
      await _cache.invalidate(cacheKey);
    }

    // Always bust the proxy cache on a Hive miss — we're hitting the API anyway,
    // and checkForUpdates() may have cleared Hive without going through the
    // startConfigWatcher path (cold-start after an admin update).
    final bust = '&_t=${DateTime.now().millisecondsSinceEpoch}';
    final data = await _getMap('/api/public/matches?season=$seasonId$bust');

    // Inject leagueCode (map key) and normalise matchId before parsing/caching,
    // so watchMatch can build the correct Firestore path.
    final enriched = data.map((league, list) {
      final enrichedList = (list as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        m['leagueCode'] ??= league;
        m['matchId'] ??= m['id'];
        return m;
      }).toList();
      return MapEntry(league, enrichedList);
    });

    final result = enriched.map(
      (league, list) =>
          MapEntry(league, list.map((e) => MatchData.fromJson(e)).toList()),
    );

    await _cache.setRaw(cacheKey, enriched, CacheService.matchesTTL);
    return result;
  }

  Future<List<MatchData>> getAllMatches(
    String leagueCode, {
    String? season,
    bool forceRefresh = false,
  }) async {
    try {
      final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
      if (forceRefresh) await _cache.invalidate('matches_all_$seasonId');

      final all = await _loadAllMatches(season: seasonId);
      return all[leagueCode] ?? [];
    } catch (e) {
      throw Exception('Greska pri dohvatu utakmica: $e');
    }
  }

  Future<List<MatchData>> getRecentFinishedMatchesByClub(
    String leagueCode,
    String clubName, {
    int limit = 10,
  }) async {
    try {
      final all = await getAllMatches(leagueCode);
      final finished =
          all
              .where(
                (m) =>
                    (m.isFinished || m.isAwarded) &&
                    (m.homeTeam == clubName || m.awayTeam == clubName),
              )
              .toList()
            ..sort((a, b) => b.matchDate.compareTo(a.matchDate));
      return finished.take(limit).toList();
    } catch (e) {
      throw Exception('Greska pri dohvatu prethodnih utakmica: $e');
    }
  }

  Future<MatchData?> getNextMatch(String leagueCode, {String? season}) async {
    try {
      final matches = await getAllMatches(leagueCode, season: season);
      final today = DateTime.now();
      final upcoming =
          matches
              .where(
                (m) =>
                    m.status == 'scheduled' &&
                    !(DateTime.tryParse(m.matchDate) ?? DateTime(1970))
                        .isBefore(DateTime(today.year, today.month, today.day)),
              )
              .toList()
            ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return upcoming.isEmpty ? null : upcoming.first;
    } catch (e) {
      throw Exception('Greska pri dohvatu sljedece utakmice: $e');
    }
  }

  Future<MatchData?> getNextMatchByClub(
    String leagueCode,
    String? homeClub,
  ) async {
    if (homeClub == null) return null;
    try {
      final matches = await getAllMatches(leagueCode);
      final today = DateTime.now();
      final upcoming =
          matches
              .where(
                (m) =>
                    m.status == 'scheduled' &&
                    !(DateTime.tryParse(m.matchDate) ?? DateTime(1970))
                        .isBefore(
                          DateTime(today.year, today.month, today.day),
                        ) &&
                    (m.homeTeam == homeClub || m.awayTeam == homeClub),
              )
              .toList()
            ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return upcoming.isEmpty ? null : upcoming.first;
    } catch (e) {
      throw Exception('Greska pri dohvatu sljedece utakmice kluba: $e');
    }
  }

  Future<MatchData?> getClosestUpcomingMatch({
    DateTime? targetDate,
    String? season,
  }) async {
    try {
      final all = await _loadAllMatches(season: season);
      final target = targetDate ?? DateTime.now();
      final upcoming =
          all.values
              .expand((matches) => matches)
              .where(
                (m) => !(DateTime.tryParse(m.matchDate) ?? DateTime(1970))
                    .isBefore(target),
              )
              .toList()
            ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return upcoming.isEmpty ? null : upcoming.first;
    } catch (e) {
      throw Exception('Greska pri dohvatu najblize utakmice: $e');
    }
  }

  Future<int> getCurrentRound(String leagueCode, {String? season}) async {
    try {
      final matches = await getAllMatches(leagueCode, season: season);
      final scheduled = matches.where((m) => m.status == 'scheduled').toList();
      if (scheduled.isEmpty) return 0;
      return scheduled.map((m) => m.round).reduce((a, b) => a > b ? a : b);
    } catch (e) {
      throw Exception('Greska pri dohvatu runde: $e');
    }
  }

  Future<List<MatchData>> getUpcomingMatches(
    String seasonId,
    String dateString,
  ) async {
    try {
      final all = await _loadAllMatches(season: seasonId);
      final allFlat = all.values.expand((m) => m).toList();
      final filtered =
          allFlat
              .where(
                (m) => m.matchDate.substring(0, 10).compareTo(dateString) >= 0,
              )
              .toList()
            ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return filtered;
    } catch (e) {
      throw Exception('Greška pri dohvatu utakmica: $e');
    }
  }

  // ── Single match real-time stream — stays on Firestore (live match) ────────

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

  // Reads a playoff match document from Firestore to restore matchState.
  // Ligaska group matches: playoff/ligaska/groups/{groupId}/matches/{matchId}
  // Liga1 bracket matches: playoff/liga1/matches/{matchId}
  Stream<MatchData> watchPlayoffMatch(
    String matchId, {
    String? playoffId,
    String? groupId,
    String? season,
  }) {
    final pid = playoffId ?? _playoffMatchPlayoffId[matchId];
    if (pid == null || pid.isEmpty) return const Stream.empty();
    final gid = groupId ?? _playoffMatchGroupId[matchId];
    final seasonId = season?.isNotEmpty == true ? season! : (_cachedSeason ?? '');

    final DocumentReference<Map<String, dynamic>> ref;
    if (gid != null && gid.isNotEmpty) {
      ref = _db
          .collection('seasons').doc(seasonId)
          .collection('playoff').doc(pid)
          .collection('groups').doc(gid)
          .collection('matches').doc(matchId);
    } else {
      ref = _db
          .collection('seasons').doc(seasonId)
          .collection('playoff').doc(pid)
          .collection('matches').doc(matchId);
    }

    return ref
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => MatchData.fromFirestore(snap.data()!, snap.id));
  }

  // ── Upcoming matches stream ────────────────────────────────────────────────
  // Replaces the collectionGroup onSnapshot (was the biggest read cost).
  // Now: loads from API once, re-fetches when onCacheInvalidated fires.

  BehaviorSubject<List<MatchData>>? _matchesSubject;
  StreamSubscription? _invalidationSub;

  Stream<List<MatchData>> getUpcomingMatchesStream({
    DateTime? targetDate,
    String? season,
  }) {
    if (_matchesSubject != null && !_matchesSubject!.isClosed) {
      return _matchesSubject!.stream;
    }

    _matchesSubject = BehaviorSubject<List<MatchData>>();

    // Serve Hive cache immediately so the UI has data before the API responds.
    // Skip stale cache entries that are missing leagueCode (pre-fix format).
    final seasonId = season ?? _cachedSeason ?? '';
    final cachedKey = 'upcoming_matches_$seasonId';
    final cachedRaw = _cache.getRaw(cachedKey);
    if (cachedRaw != null) {
      final rawList = cachedRaw as List;
      final firstMatch = rawList.isEmpty ? null : rawList.first as Map?;
      final lc = firstMatch?['leagueCode'];
      final cacheHasLeagueCode = lc != null && lc.toString().isNotEmpty;
      if (cacheHasLeagueCode) {
        _matchesSubject!.add(
          rawList
              .map(
                (e) => MatchData.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
        );
      }
    }

    // Initial load from API.
    _fetchUpcomingAndEmit(targetDate: targetDate, season: season);

    // Re-fetch whenever the admin changes match data.
    _invalidationSub ??= onCacheInvalidated.listen((_) {
      _fetchUpcomingAndEmit(
        targetDate: targetDate,
        season: season,
        forceRefresh: true,
      );
    });

    return _matchesSubject!.stream;
  }

  String _playoffRoundLabel(String round, String playoffName) {
    const names = {
      'qf': 'Četvrtfinale',
      'sf': 'Polufinale',
      'final': 'Finale',
      '3rd_place': '3. mjesto',
    };
    final r = names[round] ?? round;
    return '$r – $playoffName';
  }

  // Reads match documents directly from the ligaska group collection.
  // Returns only matches where both teams have been assigned.
  Future<List<MatchData>> getPlayoffGroupMatches(
    String groupId, {
    String? season,
  }) async {
    try {
      final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
      final snap = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('playoff')
          .doc('ligaska')
          .collection('groups')
          .doc(groupId)
          .collection('matches')
          .get();
      return snap.docs
          .map((doc) => MatchData.fromFirestore(doc.data(), doc.id))
          .where((m) => m.homeTeam.isNotEmpty && m.awayTeam.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PlayoffGroupData?> getPlayoffGroupData(
    String groupId, {
    String? season,
  }) async {
    try {
      final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
      final snap = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('playoff')
          .doc('ligaska')
          .collection('groups')
          .doc(groupId)
          .get();
      if (!snap.exists) return null;
      return PlayoffGroupData.fromFirestore(snap.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<List<MatchData>> _fetchPlayoffMatchesForStream(
      String seasonId) async {
    final info = _cachedPlayoffInfo;
    final matches = <MatchData>[];

    // Liga 1 knockout bracket — uses tie structure, matches fetched via HTTP proxy
    if (info.hasLiga1) {
      try {
        final ties = await getPlayoffTies('liga1', season: seasonId);
        for (final tie in ties) {
          final label = _playoffRoundLabel(tie.round, 'nadigravanja liga 1');
          for (final matchId in tie.allMatchIds) {
            try {
              final match = await getMatchDetail(matchId);
              _playoffMatchLabels[matchId] = label;
              _playoffMatchPlayoffId[matchId] = 'liga1';
              matches.add(match);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    // Ligaska groups — match documents live at playoff/ligaska/groups/{groupId}/matches/
    for (final group in info.ligaskaGroups) {
      try {
        final groupMatches = await getPlayoffGroupMatches(group.id, season: seasonId);
        for (final match in groupMatches) {
          _playoffMatchLabels[match.matchId] = '${group.label} – nadigravanje';
          _playoffMatchPlayoffId[match.matchId] = 'ligaska';
          _playoffMatchGroupId[match.matchId] = group.id;
          matches.add(match);
        }
      } catch (_) {}
    }

    return matches;
  }

  Future<void> _fetchUpcomingAndEmit({
    DateTime? targetDate,
    String? season,
    bool forceRefresh = false,
  }) async {
    try {
      final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
      if (forceRefresh) await _cache.invalidate('matches_all_$seasonId');

      final all = await _loadAllMatches(season: seasonId);
      final playoffMatches = await _fetchPlayoffMatchesForStream(seasonId);
      final target = targetDate ?? DateTime.now();

      bool isUpcoming(MatchData m) =>
          !(DateTime.tryParse(m.matchDate) ?? DateTime(1970))
              .isBefore(DateTime(target.year, target.month, target.day)) ||
          m.status == 'ongoing' ||
          m.status == 'paused';

      final upcoming = [
        ...all.values.expand((m) => m).where(isUpcoming),
        ...playoffMatches.where(isUpcoming),
      ]..sort((a, b) => a.matchDate.compareTo(b.matchDate));

      // Update Hive cache.
      final cacheKey = 'upcoming_matches_$seasonId';
      await _cache.setRaw(
        cacheKey,
        upcoming.map((m) => m.toJson()).toList(),
        CacheService.upcomingMatchesTTL,
      );

      if (_matchesSubject != null && !_matchesSubject!.isClosed) {
        _matchesSubject!.add(upcoming);
      }
    } catch (e) {
      if (_matchesSubject != null && !_matchesSubject!.isClosed) {
        _matchesSubject!.addError(e);
      }
    }
  }

  void disposeMatchesStream() {
    _invalidationSub?.cancel();
    _invalidationSub = null;
    _matchesSubject?.close();
    _matchesSubject = null;
  }

  // ============================================================
  // STATISTICS  — served from /api/public/stats
  // ============================================================

  Future<PlayerStatsData?> getPlayerStatsByPlayerId(
    String leagueCode,
    String playerId, {
    String? season,
  }) async {
    try {
      final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
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
        final list = await _getList(
          '/api/public/stats?league=$leagueCode&season=$seasonId',
        );
        players = list
            .map(
              (e) =>
                  PlayerStatsData.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        await _cache.setRaw(key, list, CacheService.statsTTL);
      }

      try {
        return players.firstWhere((p) => p.playerId == playerId);
      } catch (_) {
        return null;
      }
    } catch (e) {
      throw Exception('Greska pri dohvatu statistika igraca: $e');
    }
  }

  Future<Map<String, List<PlayerStatsData>>> getAllLeaguePlayerStats(
    String leagueCode, {
    String? season,
  }) async {
    final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
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
        final list = await _getList(
          '/api/public/stats?league=$leagueCode&season=$seasonId',
        );
        players = list
            .map(
              (e) =>
                  PlayerStatsData.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        await _cache.setRaw(key, list, CacheService.statsTTL);
      } catch (e) {
        throw Exception('Greska pri dohvatu statistika igraca: $e');
      }
    }

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

  // ============================================================
  // STANDINGS  — served from /api/public/standings
  // ============================================================

  Future<List<ClubStanding>> getAllClubsInLeague(
    String leagueCode, {
    String? season,
  }) async {
    final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
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
      final data = await _getMap('/api/public/standings?season=$seasonId');
      // Cache each league separately (existing cache key pattern).
      for (final entry in data.entries) {
        final leagueKey = 'standings_${entry.key}_$seasonId';
        await _cache.setRaw(leagueKey, entry.value, CacheService.standingsTTL);
      }

      final leagueList = data[leagueCode] as List? ?? [];
      return leagueList
          .map(
            (e) => ClubStanding.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (e) {
      throw Exception('Greška pri dohvaćanju klubova u ligi: $e');
    }
  }

  Future<ClubStanding?> getBestClubInLeague(String leagueCode) async {
    try {
      final standings = await getAllClubsInLeague(leagueCode);
      return standings.isEmpty ? null : standings.first;
    } catch (e) {
      throw Exception('Greska pri pronalasku najboljeg tima u lizi: $e');
    }
  }

  Future<Map<String, List<MatchData>>> getLastFiveMatchScores(
    String leagueCode, {
    String? season,
  }) async {
    try {
      final seasonId = season ?? _cachedSeason;
      final standingsList = await getAllClubsInLeague(
        leagueCode,
        season: seasonId,
      );
      final allMatches = await getAllMatches(leagueCode, season: seasonId);
      final result = <String, List<MatchData>>{};
      for (final s in standingsList) {
        result[s.clubName] = allMatches
            .where((m) => m.homeTeam == s.clubName || m.awayTeam == s.clubName)
            .take(5)
            .toList();
      }
      return result;
    } catch (e) {
      throw Exception('Greška pri dohvaćanju zadnjih meceva za svaki klub: $e');
    }
  }

  // ============================================================
  // NEWS  — served from /api/public/news
  // ============================================================

  Future<List<NewsData>> _loadAllNews() async {
    const key = 'news_all';

    final cached = _cache.getRaw(key);
    if (cached != null) {
      return (cached as List)
          .map((e) => NewsData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final data = await _getMap('/api/public/news');
    final list = data['items'] as List<dynamic>;
    await _cache.setRaw(key, list, CacheService.newsTTL);
    return list
        .map((e) => NewsData.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<NewsPaginated> getNewsPaginated({
    int limit = 5,
    int offset = 0,
  }) async {
    try {
      final all = await _loadAllNews();
      final slice = all.skip(offset).take(limit).toList();
      return NewsPaginated(
        items: slice,
        offset: offset + slice.length,
        hasMore: offset + slice.length < all.length,
      );
    } catch (e) {
      throw Exception('Greska pri dohvatu vijesti: $e');
    }
  }

  Future<NewsData?> getLatestNews() async {
    try {
      final all = await _loadAllNews();
      return all.isEmpty ? null : all.first;
    } catch (e) {
      throw Exception('Greska pri dohvatu vijesti: $e');
    }
  }

  // ============================================================
  // PLAYOFFS  — checked once at startup, cached in memory
  // ============================================================

  PlayoffInfo _cachedPlayoffInfo =
      const PlayoffInfo(hasLiga1: false, ligaskaGroups: []);
  PlayoffInfo get cachedPlayoffInfo => _cachedPlayoffInfo;

  // matchId → round label, e.g. "Četvrtfinale – nadigravanja liga 1"
  final Map<String, String> _playoffMatchLabels = {};
  Map<String, String> get playoffMatchLabels =>
      Map.unmodifiable(_playoffMatchLabels);

  // matchId → playoffId, used to read matchState from Firestore for playoff matches
  final Map<String, String> _playoffMatchPlayoffId = {};
  // matchId → groupId, for ligaska group matches (path: playoff/ligaska/groups/{groupId}/matches)
  final Map<String, String> _playoffMatchGroupId = {};

  bool isPlayoffMatch(String matchId) => _playoffMatchPlayoffId.containsKey(matchId);

  Future<PlayoffInfo> checkPlayoffs() async {
    try {
      final season = _cachedSeason ?? await getActiveSeason();
      debugPrint('[Playoffs] checking season: $season');

      // playoff is a subcollection directly on the season doc, not under leagues
      final playoffRef = _db
          .collection('seasons')
          .doc(season)
          .collection('playoff');

      debugPrint('[Playoffs] querying: seasons/$season/playoff');
      final liga1Doc = await playoffRef.doc('liga1').get();
      final hasLiga1 = liga1Doc.exists &&
          (liga1Doc.data()?['status'] as String?) == 'in_progress';
      debugPrint('[Playoffs] hasLiga1: $hasLiga1');

      final ligaskaGroups = <PlayoffGroupInfo>[];
      final groupsSnap =
          await playoffRef.doc('ligaska').collection('groups').get();
      debugPrint('[Playoffs] groups docs: ${groupsSnap.docs.length}');
      for (final groupDoc in groupsSnap.docs) {
        final label = groupDoc.data()['label'] as String? ?? groupDoc.id;
        ligaskaGroups.add(PlayoffGroupInfo(id: groupDoc.id, label: label));
      }

      _cachedPlayoffInfo = PlayoffInfo(hasLiga1: hasLiga1, ligaskaGroups: ligaskaGroups);
      debugPrint('[Playoffs] season=$season hasLiga1=$hasLiga1 groups=${ligaskaGroups.map((g) => g.id)}');
      return _cachedPlayoffInfo;
    } catch (e) {
      debugPrint('[Playoffs] checkPlayoffs error: $e');
      return const PlayoffInfo(hasLiga1: false, ligaskaGroups: []);
    }
  }

  // ============================================================
  // PLAYOFF TIES  — fetched directly from Firestore
  // ============================================================

  /// Fetches all tie documents for the given [playoffId] (e.g. "liga1").
  /// Path: seasons/{season}/playoff/{playoffId}/ties/{tieId}
  Future<List<PlayoffTie>> getPlayoffTies(
    String playoffId, {
    String? season,
  }) async {
    try {
      final seasonId = season ?? _cachedSeason ?? await getActiveSeason();
      final snap = await _db
          .collection('seasons')
          .doc(seasonId)
          .collection('playoff')
          .doc(playoffId)
          .collection('ties')
          .get();
      return snap.docs
          .map((doc) => PlayoffTie.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Greška pri dohvatu playoff susreta: $e');
    }
  }

  // ============================================================
  // TOURNAMENTS  — top-level `tournaments` collection in Firestore
  // ============================================================

  // Every key below starts with 'tournaments_' so the 'lastUpdatedTournaments'
  // entry in [_categoryPrefixes] clears all of them in one sweep.

  /// All tournament documents, newest season first. Callers split them by
  /// [TournamentData.isActive]: active → main section, inactive → archive.
  Future<List<TournamentData>>? _tournamentsInFlight;

  Future<List<TournamentData>> getTournaments() async {
    const cacheKey = 'tournaments_all';

    final cached = _cache.getRaw(cacheKey);
    if (cached != null) {
      final list = (cached as List)
          .map((e) => TournamentData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      list.sort((a, b) => b.seasonStamp.compareTo(a.seasonStamp));
      return list;
    }

    // An invalidation wakes every open tournament page at once, so several
    // callers hit the empty cache in the same tick. Share one collection read
    // between them instead of paying for N.
    return _tournamentsInFlight ??= _fetchTournaments(cacheKey)
        .whenComplete(() => _tournamentsInFlight = null);
  }

  Future<List<TournamentData>> _fetchTournaments(String cacheKey) async {
    try {
      final snap = await _db.collection('tournaments').get();
      final list = snap.docs
          .map((d) => TournamentData.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.seasonStamp.compareTo(a.seasonStamp));
      await _cache.setRaw(
        cacheKey,
        list.map((t) => t.toJson()).toList(),
        CacheService.tournamentsTTL,
      );
      return list;
    } catch (e) {
      throw Exception('Greška pri dohvatu turnira: $e');
    }
  }

  /// Bracket ties for a tournament: tournaments/{id}/ties/{qf_0, sf_1, final, …}
  Future<List<PlayoffTie>> getTournamentTies(String tournamentId) async {
    final cacheKey = 'tournaments_ties_$tournamentId';

    final cached = _cache.getRaw(cacheKey);
    if (cached != null) {
      return (cached as List)
          .map((e) => PlayoffTie.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    try {
      final snap = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('ties')
          .get();
      final ties = snap.docs
          .map((doc) => PlayoffTie.fromFirestore(doc.id, doc.data()))
          .toList();
      await _cache.setRaw(
        cacheKey,
        ties.map((t) => t.toJson()).toList(),
        CacheService.tournamentsTTL,
      );
      return ties;
    } catch (e) {
      throw Exception('Greška pri dohvatu ždrijeba turnira: $e');
    }
  }

  Future<List<TournamentTeam>> getTournamentTeams(String tournamentId) async {
    final cacheKey = 'tournaments_teams_$tournamentId';

    final cached = _cache.getRaw(cacheKey);
    if (cached != null) {
      final teams = (cached as List)
          .map((e) => TournamentTeam.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      teams.sort((a, b) => a.name.compareTo(b.name));
      return teams;
    }

    try {
      final snap = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .get();
      final teams = snap.docs
          .map((d) => TournamentTeam.fromFirestore(d.id, d.data()))
          .toList();
      teams.sort((a, b) => a.name.compareTo(b.name));
      await _cache.setRaw(
        cacheKey,
        teams.map((t) => t.toJson()).toList(),
        CacheService.tournamentsTTL,
      );
      return teams;
    } catch (e) {
      throw Exception('Greška pri dohvatu momčadi turnira: $e');
    }
  }

  Future<List<TournamentPlayer>> getTournamentTeamPlayers(
    String tournamentId,
    String teamId,
  ) async {
    final cacheKey = 'tournaments_players_${tournamentId}_$teamId';

    final cached = _cache.getRaw(cacheKey);
    if (cached != null) {
      final players = (cached as List)
          .map((e) =>
              TournamentPlayer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      players.sort((a, b) => a.name.compareTo(b.name));
      return players;
    }

    try {
      final snap = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(teamId)
          .collection('players')
          .get();
      final players = snap.docs
          .map((d) => TournamentPlayer.fromFirestore(d.id, d.data()))
          .toList();
      players.sort((a, b) => a.name.compareTo(b.name));
      await _cache.setRaw(
        cacheKey,
        players.map((p) => p.toJson()).toList(),
        CacheService.tournamentsTTL,
      );
      return players;
    } catch (e) {
      throw Exception('Greška pri dohvatu igrača momčadi: $e');
    }
  }

  // ============================================================
  // SPONSORS  — served from /api/public/sponsors
  // ============================================================

  Future<List<SponsorData>> getSponsors() async {
    const key = 'sponsors';
    final cached = _cache.getRaw(key);
    if (cached != null) {
      return (cached as List)
          .map((e) => SponsorData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    try {
      final list = await _getList('/api/public/sponsors');
      await _cache.setRaw(key, list, CacheService.sponsorsTTL);
      return list
          .map((e) => SponsorData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Greška pri dohvatu sponzora: $e');
    }
  }
}
