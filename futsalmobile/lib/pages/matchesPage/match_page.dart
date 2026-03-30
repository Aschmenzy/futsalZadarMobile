import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/pages/matchesPage/widgets/calendar_container.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/shimmer_loading.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';
import 'package:futsalmobile/widgets/utakmica_container.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  final _service = FirebaseService();

  late Stream<List<MatchData>> _matchesStream;
  List<MatchData>? _cachedMatches;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _matchesStream = _service.getUpcomingMatchesStream();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 32, right: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('assets/images/logo.png', scale: 0.7),
                ),

                SizedBox(height: screenHeight * 0.035),

                CalendarCard(
                  currentDate: _selectedDate,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.035),

                SponsorsBanner(),

                SizedBox(height: screenHeight * 0.035),

                Text(
                  "Utakmice",
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: screenHeight * 0.035),

                Expanded(
                  child: StreamBuilder<List<MatchData>>(
                    stream: _matchesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        if (_cachedMatches != null &&
                            _cachedMatches!.isNotEmpty) {
                          return _buildMatchesList(
                            _cachedMatches!,
                            _selectedDate,
                          );
                        }
                        return Center(
                          child: ShimmerLoading(
                            width: double.infinity,
                            height: screenHeight * 0.18,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        if (_cachedMatches != null &&
                            _cachedMatches!.isNotEmpty) {
                          return _buildMatchesList(
                            _cachedMatches!,
                            _selectedDate,
                          );
                        }
                        return Center(
                          child: Text(
                            'Greška pri učitavanju: ${snapshot.error}',
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        if (_cachedMatches != null &&
                            _cachedMatches!.isNotEmpty) {
                          return _buildMatchesList(
                            _cachedMatches!,
                            _selectedDate,
                          );
                        }
                        return Center(child: Text('Nema dostupnih utakmica'));
                      }

                      _cachedMatches = snapshot.data!;
                      return _buildMatchesList(_cachedMatches!, _selectedDate);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildMatchesList(List<MatchData> matches, DateTime _selectedDate) {
  final filtered = _filterMatchesByDate(matches, _selectedDate);

  if (filtered.isEmpty) {
    return Center(
      child: Text(
        'Nema utakmica za ovaj datum',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  return ListView.separated(
    itemCount: filtered.length,
    separatorBuilder: (_, _) => SizedBox(height: 10),
    itemBuilder: (context, i) => UtakmicaContainer(
      matchStatus: filtered[i].status,
      team1Name: filtered[i].homeTeam,
      team2Name: filtered[i].awayTeam,
      team1Logo: filtered[i].homeTeamLogo,
      team2Logo: filtered[i].awayTeamLogo,
      team1Score: filtered[i].homeTeamGoals,
      team2Score: filtered[i].awayTeamGoals,
      matchTime: _formatMatchDate(filtered[i].matchTime),
    ),
  );
}

List<MatchData> _filterMatchesByDate(List<MatchData> matches, DateTime date) {
  return matches.where((match) {
    if (match.matchDate.isEmpty) return false;
    try {
      final matchDate = DateTime.parse(match.matchDate);
      return _isSameDay(matchDate, date);
    } catch (_) {
      return false;
    }
  }).toList();
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatMatchDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return "${date.day}.${date.month}.${date.year}";
  } catch (_) {
    return dateString;
  }
}
