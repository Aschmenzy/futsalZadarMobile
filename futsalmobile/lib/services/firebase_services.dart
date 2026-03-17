import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:futsalmobile/models/clubStanding.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';
import 'package:futsalmobile/models/news/news_data.dart';
import 'package:futsalmobile/models/news/news_paginated.dart';
import 'package:flutter/foundation.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_data.dart';

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

  //dohvati sve sezone
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
  // IGRACI I MECEVI
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

  Future<List<MatchData>> getAllMatches(
    String leagueCode, {
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
          .collection('matches')
          .orderBy('matchDate', descending: true)
          .orderBy('matchTime')
          .get();

      return snapshot.docs.map((doc) {
        try {
          return MatchData.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Exception('Greska pri dohvatu utakmica: $e');
    }
  }

  // ============================================================
  // STATISTIKE
  // ============================================================

  Future<List<PlayerStatsData>> getLeadingPlayersByGoals(
    String leagueCode, {
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
          .get();

      if (snapshot.docs.isEmpty) return [];

      final players = snapshot.docs
          .map((doc) => PlayerStatsData.fromFirestore(doc.data(), doc.id))
          .toList();

      players.sort((a, b) {
        final totalA = a.goals + a.goals10m + a.goals6m;
        final totalB = b.goals + b.goals10m + b.goals6m;
        return totalB.compareTo(totalA);
      });

      return players.take(5).toList();
    } catch (e) {
      throw Exception(
        'Greska pri dohvatu najboljih igraca po broju golova: $e',
      );
    }
  }

  Future<List<PlayerStatsData>> getLeadingPlayersByRedCards(
    String leagueCode, {
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
          .orderBy('redCards', descending: true)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => PlayerStatsData.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(
        'Greska pri dohvatu najboljih igraca po broju crvenih kartona: $e',
      );
    }
  }

  Future<List<PlayerStatsData>> getLeadingPlayersByYellowCards(
    String leagueCode, {
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
          .orderBy('yellowCards', descending: true)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => PlayerStatsData.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Greska pri dohvatu igraca po broju zutih kartona: $e');
    }
  }

  Future<Map<String, List<PlayerStatsData>>> getPlayersByActiveYellows(
    String leagueCode, {
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
          .where('activeYellows', isGreaterThan: 0)
          .get();

      if (snapshot.docs.isEmpty) return {'oneYellow': [], 'twoYellows': []};

      final players = snapshot.docs
          .map((doc) => PlayerStatsData.fromFirestore(doc.data(), doc.id))
          .toList();

      return {
        'oneYellow': players
            .where((p) => p.activeYellows == 1)
            .take(5)
            .toList(),
        'twoYellows': players
            .where((p) => p.activeYellows == 2)
            .take(5)
            .toList(),
      };
    } catch (e) {
      throw Exception('Greska pri dohvatu igraca po zutim kartonima: $e');
    }
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

      print("leaugeCode : $leagueCode, sezona je $_cachedSeason");

      final doc = snapshot.docs.first;
      return ClubStanding.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Greska pri pronalasku najboljeg tima u lizi: $e');
    }
  }

  // ============================================================
  // TABLICE
  // ============================================================
    Future<List<ClubStanding>> getAllClubsInLeague(
    String leagueCode, {
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
          .collection('standings')
          .orderBy('points', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return [];

      print("leagueCode: $leagueCode, sezona je $_cachedSeason");

      return snapshot.docs
          .map((doc) => ClubStanding.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Greška pri dohvaćanju klubova u ligi: $e');
    }
  }

  //funkcija za dohvacanje zadnjih stanja zadnjih 5 meceva
  //prvo treba otic u collection liga[1,2,3,4] te ic po svakom dokumentu i gledati club name
  //onda treba ici u seasons/[seasonID]/leauges/liga[1,2,3,4]/matches pa po svakom dokumentu gledati 
  //je li clubName == awayTeam ili clubName == homeTeam
  Future<Map<String, List<MatchData>>> getLastFiveMatchScores(String leagueCode, {String? season}) async {
  try {
    final seasonId = (season != null && season.isNotEmpty)
        ? season
        : _cachedSeason;

    // 1. Dohvati klubove sortirane po bodovima iz standings kolekcije
    final standingsSnapshot = await _db
        .collection('seasons')
        .doc(seasonId)
        .collection('leagues')
        .doc(leagueCode)
        .collection('standings')
        .orderBy('points', descending: true)
        .get();

    if (standingsSnapshot.docs.isEmpty) return {};

    // 2. Dohvati sve mečeve jednom
    final matchesSnapshot = await _db
        .collection('seasons')
        .doc(seasonId)
        .collection('leagues')
        .doc(leagueCode)
        .collection('matches')
        .orderBy('matchDate', descending: true)
        .get();

    // 3. Pretvori sve mečeve u listu jednom
    final allMatches = matchesSnapshot.docs
        .map((doc) => MatchData.fromFirestore(doc.data(), doc.id))
        .toList();

    // 4. Za svaki klub (već sortiran po bodovima) filtriraj zadnjih 5 mečeva
    final Map<String, List<MatchData>> result = {};

    for (final standingDoc in standingsSnapshot.docs) {
      final clubName = standingDoc.data()['clubName'] as String?;
      if (clubName == null) continue;

      result[clubName] = allMatches
          .where((match) =>
              match.homeTeam == clubName || match.awayTeam == clubName)
          .take(5)
          .toList();
    }

    return result;
  } catch (e) {
    throw Exception('Greška pri dohvaćanju zadnjih meceva za svaki klub: $e');
  }
}

  // ============================================================
  // VIJESTI
  // ============================================================

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

  Future<NewsData?> getLatestNews() async {
    try {
      final snapshot = await _db
          .collection('seasons')
          .doc(_cachedSeason)
          .collection('news')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return NewsData.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Greska pri dohvatu vijesti: $e');
    }
  }
}
