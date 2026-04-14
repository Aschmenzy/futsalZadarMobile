import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:futsalmobile/models/favorite_item.dart';
import 'package:futsalmobile/services/auth_service.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'main',
  );

  CollectionReference<Map<String, dynamic>>? get _favCollection {
    final uid = AuthService.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('favorites');
  }

  // Stream of all starred favorites (clubs, players, leagues).
  // No orderBy — avoids requiring a composite index. Sorted in Dart.
  Stream<List<FavoriteItem>> get starredStream {
    final col = _favCollection;
    debugPrint('[FAV] starredStream — uid=${AuthService.uid}, col=${col == null ? "NULL" : "OK"}');
    if (col == null) return const Stream.empty();
    return col
        .where('starred', isEqualTo: true)
        .snapshots()
        .map((snap) {
          debugPrint('[FAV] starredStream snapshot — ${snap.docs.length} docs');
          final items =
              snap.docs.map((d) => FavoriteItem.fromMap(d.data())).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Stream of match notification subscriptions.
  // No compound orderBy — avoids composite index requirement.
  Stream<List<FavoriteItem>> get matchNotificationsStream {
    final col = _favCollection;
    if (col == null) return const Stream.empty();
    return col
        .where('type', isEqualTo: 'match')
        .where('notificationsEnabled', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final items =
              snap.docs.map((d) => FavoriteItem.fromMap(d.data())).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Stream for a single entity — used by buttons to react to changes.
  Stream<FavoriteItem?> watchEntity(String entityId) {
    final col = _favCollection;
    debugPrint('[FAV] watchEntity — uid=${AuthService.uid}, entityId=$entityId, col=${col == null ? "NULL" : "OK"}');
    if (col == null) return const Stream.empty();
    return col.doc(entityId).snapshots().map((snap) {
      debugPrint('[FAV] watchEntity snapshot — exists=${snap.exists}, path=${snap.reference.path}');
      if (!snap.exists) return null;
      return FavoriteItem.fromMap(snap.data()!);
    });
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> toggleStar(FavoriteItem item) async {
    final col = _favCollection;
    debugPrint('[FAV] toggleStar — uid=${AuthService.uid}, entityId=${item.entityId}, type=${item.type}');
    if (col == null) {
      debugPrint('[FAV] toggleStar — col is null (not logged in)');
      return 'Korisnik nije prijavljen.';
    }
    try {
      final doc = col.doc(item.entityId);
      final snap = await doc.get();
      debugPrint('[FAV] toggleStar — doc exists=${snap.exists}');
      if (!snap.exists) {
        await doc.set(item.copyWith(starred: true).toMap());
        debugPrint('[FAV] toggleStar — created new doc at ${doc.path}');
      } else {
        final current = FavoriteItem.fromMap(snap.data()!);
        final newStarred = !current.starred;
        if (!newStarred && !current.notificationsEnabled) {
          await doc.delete();
          debugPrint('[FAV] toggleStar — deleted doc (unstarred, no notif)');
        } else {
          await doc.update({
            'starred': newStarred,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('[FAV] toggleStar — updated starred=$newStarred');
        }
      }
      return null;
    } catch (e) {
      debugPrint('[FAV] toggleStar — ERROR: $e');
      return e.toString();
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> toggleNotification(FavoriteItem item) async {
    final col = _favCollection;
    if (col == null) return 'Korisnik nije prijavljen.';
    try {
      final doc = col.doc(item.entityId);
      final snap = await doc.get();
      if (!snap.exists) {
        await doc.set(item.copyWith(notificationsEnabled: true).toMap());
      } else {
        final current = FavoriteItem.fromMap(snap.data()!);
        final newNotif = !current.notificationsEnabled;
        if (!newNotif && !current.starred) {
          await doc.delete();
        } else {
          await doc.update({
            'notificationsEnabled': newNotif,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> removeFromFavorites(String entityId) async {
    await _favCollection?.doc(entityId).delete();
  }
}
