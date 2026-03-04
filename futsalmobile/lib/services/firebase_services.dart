import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/news/news_data.dart';
import 'package:futsalmobile/models/news/news_paginated.dart';
import 'package:futsalmobile/models/player_data.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'main',
  );

  // Singleton pattern - jedna instanca kroz cijelu aplikaciju
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  // ============================================================
  // DOHVACANJE TRENUTE SEZONE
  // ============================================================

    String? _cachedSeason;

    /// Dohvati aktivnu sezonu — cachira rezultat
Future<String> getActiveSeason({bool forceRefresh = false}) async {
  if (_cachedSeason != null && !forceRefresh) return _cachedSeason!;

  try {
    final doc = await _db.collection('config').doc('app').get();

    if (!doc.exists) {
      throw Exception('Config dokument ne postoji');
    }

    _cachedSeason = doc.data()?['activeSeason'] ?? '';
    return _cachedSeason!;
  } catch (e) {
    throw Exception('Greska pri dohvatu aktivne sezone: $e');
  }
}

/// Resetiraj cache (npr. kod pull-to-refresh)
void clearCache() {
  _cachedSeason = null;
}



  // ============================================================
  // KLUBOVI
  // ============================================================

  /// Dohvati sve klubove iz odredene lige
  /// [leagueId] - "liga1", "liga2", "liga3", "liga4"
  Future<List<ClubData>> getClubsByLeague(String leagueId) async {
    try {
      final snapshot = await _db.collection(leagueId).get();

      return snapshot.docs.map((doc) {
        return ClubData.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Greska pri dohvatu klubova: $e');
    }
  }

  /// Dohvati jedan klub po ID-u
  Future<ClubData?> getClubById(String leagueId, String clubId) async {
    try {
      final doc = await _db.collection(leagueId).doc(clubId).get();

      if (!doc.exists) return null;
      return ClubData.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Greska pri dohvatu kluba: $e');
    }
  }

  /// Dohvati samo broj klubova u ligi
  Future<int> getClubCount(String leagueId) async {
    try {
      final snapshot = await _db.collection(leagueId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Greska pri dohvatu broja klubova: $e');
    }
  }

  // ============================================================
  // IGRACI
  // ============================================================

  /// Dohvati sve igrace jednog kluba
  /// [leagueId] - "liga1", "liga2", itd.
  /// [clubId] - document ID kluba
  Future<List<PlayerData>> getPlayersByClub(
    String leagueId,
    String clubId,
  ) async {
    try {
      final snapshot = await _db
          .collection(leagueId)
          .doc(clubId)
          .collection('players')
          .get();

      return snapshot.docs.map((doc) {
        return PlayerData.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Greska pri dohvatu igraca: $e');
    }
  }

  /// Dohvati klub zajedno s igracima (sve u jednom pozivu)
  Future<ClubData> getClubWithPlayers(String leagueId, String clubId) async {
    final club = await getClubById(leagueId, clubId);
    if (club == null) {
      throw Exception('Klub $clubId ne postoji u $leagueId');
    }

    final players = await getPlayersByClub(leagueId, clubId);
    return club.copyWithPlayers(players);
  }

  /// Dohvati sve klubove s igracima za cijelu ligu
  /// PAZNJA: Ovo radi puno Firestore citanja - koristi samo kad je stvarno potrebno
  Future<List<ClubData>> getLeagueWithAllPlayers(String leagueId) async {
    final clubs = await getClubsByLeague(leagueId);

    final clubsWithPlayers = await Future.wait(
      clubs.map((club) async {
        final players = await getPlayersByClub(leagueId, club.id);
        return club.copyWithPlayers(players);
      }),
    );

    return clubsWithPlayers;
  }

  // Vijesti, funkcija vraca vijesti 5 po 5
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
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => NewsData.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
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

Future<MatchData?> getNextMatch(String leagueCode) async {
  try {
    
    final snapshot = await _db
        .collection('seasons')
        .doc(_cachedSeason)
        .collection('leagues')
        .doc(leagueCode)
        .collection('matches')
        .where('status', isEqualTo: 'scheduled')
        .orderBy('matchDate')
        .orderBy('matchTime')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return MatchData.fromFirestore(doc.data(), doc.id);
  } catch (e) {
    throw Exception('Greska pri dohvatu sljedece utakmice: $e');
  }
}

  // TODO: Sezone
  // Future<List<SeasonData>> getSeasons() async { }
  // Future<SeasonData> getCurrentSeason() async { }

  // TODO: Podatci prosle sezone
  // Future<List<ClubData>> getClubsBySeason(String seasonId, String leagueId) async { }
}
