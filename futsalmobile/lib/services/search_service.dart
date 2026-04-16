import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:futsalmobile/services/firebase_services.dart';

class PlayerSearchResult {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? photoUrl;
  final String league;
  final String clubId;
  final String clubName;
  final String? position;

  const PlayerSearchResult({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.photoUrl,
    required this.league,
    required this.clubId,
    required this.clubName,
    this.position,
  });

  factory PlayerSearchResult.fromMap(Map<String, dynamic> m) {
    final first = (m['firstName']?.toString() ?? '').trim();
    final last = (m['lastName']?.toString() ?? '').trim();
    return PlayerSearchResult(
      id: m['id']?.toString() ?? m['_id']?.toString() ?? '',
      firstName: first,
      lastName: last,
      fullName: '$first $last',
      photoUrl: m['profilePhoto']?.toString() ?? m['profilePicture']?.toString(),
      league: m['_league']?.toString() ?? '',
      clubId: m['_clubId']?.toString() ?? '',
      clubName: m['clubName']?.toString() ?? '',
      position: m['position']?.toString(),
    );
  }
}

class _IndexEntry {
  final String searchKey;
  final PlayerSearchResult result;
  const _IndexEntry(this.searchKey, this.result);
}

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;

  SearchService._internal() {
    _invalidationSub = FirebaseService().onCacheInvalidated.listen((_) {
      invalidate();
    });
  }

  static const _cacheBoxName = 'search_cache';
  static const _cacheKey = 'players_index_raw';
  static const _cacheTtlMs = 24 * 60 * 60 * 1000;

  List<_IndexEntry>? _index;
  bool _loading = false;
  final List<Completer<void>> _waiters = [];
  StreamSubscription<void>? _invalidationSub;

  Future<void> ensureIndexLoaded({
    String? season,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) invalidate();
    if (_index != null) return;

    if (_loading) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future;
      return;
    }

    _loading = true;
    try {
      final raw = await _loadPlayers();
      final entries = <_IndexEntry>[];
      for (final m in raw) {
        try {
          final map = Map<String, dynamic>.from(m as Map);
          final r = PlayerSearchResult.fromMap(map);
          if (r.firstName.isNotEmpty || r.lastName.isNotEmpty) {
            entries.add(_IndexEntry(r.fullName.toLowerCase(), r));
          }
        } catch (_) {}
      }
      _index = entries;
      debugPrint('[SearchService] index built: ${_index!.length} entries');
    } catch (e) {
      debugPrint('[SearchService] index build failed: $e');
      // Leave _index as null so the next search attempt retries.
    } finally {
      _loading = false;
      for (final c in _waiters) {
        c.complete();
      }
      _waiters.clear();
    }
  }

  Future<List<PlayerSearchResult>> search(String query) async {
    await ensureIndexLoaded();
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return (_index ?? [])
        .where((e) => e.searchKey.contains(q))
        .map((e) => e.result)
        .toList();
  }

  void invalidate() {
    _index = null;
    _evictHiveCache();
  }

  void dispose() {
    _invalidationSub?.cancel();
    _invalidationSub = null;
  }

  Future<List<dynamic>> _loadPlayers() async {
    final box = await Hive.openBox(_cacheBoxName);
    final raw = box.get(_cacheKey) as List?;
    final tsMs = box.get('${_cacheKey}_ts') as int?;

    if (raw != null && tsMs != null) {
      final age = DateTime.now().millisecondsSinceEpoch - tsMs;
      if (age < _cacheTtlMs) return raw;
    }

    final uri = Uri.parse('$kApiBaseUrl/api/public/players');
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('[SearchService] API ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as List<dynamic>;
    await box.put(_cacheKey, decoded);
    await box.put('${_cacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
    return decoded;
  }

  Future<void> _evictHiveCache() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.delete(_cacheKey);
      await box.delete('${_cacheKey}_ts');
    } catch (_) {}
  }
}
