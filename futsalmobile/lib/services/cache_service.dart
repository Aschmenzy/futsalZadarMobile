import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'futsal_cache';
  static Box? _box;

  // ── TTL constants ──────────────────────────────────────────────────────────
  static const Duration seasonTTL = Duration(hours: 24);
  static const Duration clubsTTL = Duration(days: 7);
  static const Duration playersTTL = Duration(hours: 24);
  static const Duration standingsTTL = Duration(hours: 1);
  static const Duration statsTTL = Duration(hours: 1);
  static const Duration matchesTTL = Duration(minutes: 30);
  static const Duration upcomingMatchesTTL = Duration(minutes: 2);
  static const Duration newsTTL = Duration(minutes: 30);
  static const Duration searchIndexTTL = Duration(hours: 24);
  static const Duration sponsorsTTL = Duration(hours: 24);

  // ── Singleton ──────────────────────────────────────────────────────────────
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Box get _b {
    assert(_box != null, 'CacheService.init() must be called before use');
    return _box!;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns true if [key] exists and its TTL has not expired.
  bool isValid(String key) {
    final entry = _b.get(key);
    if (entry == null) return false;
    final expiry = DateTime.tryParse((entry as Map)['expiry'] as String? ?? '');
    return expiry != null && DateTime.now().isBefore(expiry);
  }

  /// Returns the decoded JSON value for [key], or null if missing / expired.
  dynamic getRaw(String key) {
    if (!isValid(key)) return null;
    final encoded = (_b.get(key) as Map)['data'] as String?;
    if (encoded == null) return null;
    return jsonDecode(encoded);
  }

  /// Like [getRaw] but ignores TTL — returns last-known value even if expired.
  dynamic getRawStale(String key) {
    final entry = _b.get(key);
    if (entry == null) return null;
    final encoded = (entry as Map)['data'] as String?;
    if (encoded == null) return null;
    return jsonDecode(encoded);
  }

  /// Stores [data] (must be JSON-encodable) under [key] with [ttl].
  Future<void> setRaw(String key, dynamic data, Duration ttl) async {
    await _b.put(key, {
      'data': jsonEncode(data),
      'expiry': DateTime.now().add(ttl).toIso8601String(),
    });
  }

  /// Removes the entry for [key] so the next read goes to Firestore.
  Future<void> invalidate(String key) async => _b.delete(key);

  /// Wipes the entire cache box (e.g. on season change).
  Future<void> clearAll() async => _b.clear();

  // ── Server-driven invalidation ─────────────────────────────────────────────

  String _syncKey(String category) => '__last_synced_${category}__';

  /// Returns the last sync timestamp for [category], or null if never synced.
  /// Use distinct categories (e.g. 'matches', 'players') so each data type
  /// can be invalidated independently without clearing unrelated caches.
  DateTime? getLastSyncedAt({String category = 'global'}) {
    final val = _b.get(_syncKey(category)) as String?;
    return val != null ? DateTime.tryParse(val) : null;
  }

  /// Stores the sync timestamp for [category].
  Future<void> setLastSyncedAt(DateTime dt, {String category = 'global'}) async {
    await _b.put(_syncKey(category), dt.toIso8601String());
  }

  /// Deletes every cache entry whose key starts with any of [prefixes].
  /// Used for selective invalidation — only wipes the affected data type.
  Future<void> invalidateByPrefixes(List<String> prefixes) async {
    final toDelete = _b.keys
        .whereType<String>()
        .where((k) => prefixes.any((p) => k.startsWith(p)))
        .toList();
    await _b.deleteAll(toDelete);
  }
}
