import 'club_data.dart';

class LeagueData {
  final String id;
  final int leagueNumber; // 1-4
  final List<ClubData> clubs;
  final int currentRound; // treba napisati logiku koja gleda koja je runda

  const LeagueData({
    required this.id,
    required this.leagueNumber,
    required this.clubs,
    this.currentRound = 13,
  });

  String get name => '$leagueNumber. futsal liga Zadar';

  int get teamCount => clubs.length;

  // 1st is highest, 4th is lowest
  String? get higherLeagueName =>
      leagueNumber > 1 ? '${leagueNumber - 1}. futsal liga Zadar' : null;

  String? get lowerLeagueName =>
      leagueNumber < 4 ? '${leagueNumber + 1}. futsal liga Zadar' : null;
}
