import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:futsalmobile/pages/leaguePage/models/club_data.dart';
import 'package:futsalmobile/pages/leaguePage/models/player_data.dart';

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

  // ============================================================
  // BUDUCE METODE (placeholder za kasnije)
  // ============================================================

  // TODO: Vijesti
  // Future<List<NewsData>> getNews() async { }

  // TODO: Sezone
  // Future<List<SeasonData>> getSeasons() async { }
  // Future<SeasonData> getCurrentSeason() async { }

  // TODO: Podatci prosle sezone
  // Future<List<ClubData>> getClubsBySeason(String seasonId, String leagueId) async { }
}
