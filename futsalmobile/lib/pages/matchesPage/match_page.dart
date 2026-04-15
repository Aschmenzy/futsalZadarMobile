import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/favorite_item.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/pages/matchDetailsPage/match_details_page.dart';
import 'package:futsalmobile/pages/matchesPage/widgets/calendar_container.dart';
import 'package:futsalmobile/services/favorites_service.dart';
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
  final _favService = FavoritesService();

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

  Widget _buildMatchesList(List<MatchData> matches, DateTime selectedDate) {
    final filtered = _filterMatchesByDate(matches, selectedDate);

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
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final match = filtered[i];
        if (match.status != 'scheduled') {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MatchDetailsPage(match: match),
              ),
            ),
            child: UtakmicaContainer(
              matchStatus: match.status,
              team1Name: match.homeTeam,
              team2Name: match.awayTeam,
              team1Logo: match.homeTeamLogo,
              team2Logo: match.awayTeamLogo,
              team1Score: match.homeTeamGoals,
              team2Score: match.awayTeamGoals,
              matchTime: _formatMatchTime(match.matchTime),
            ),
          );
        }
        // Scheduled matches get notification bell via StreamBuilder
        return StreamBuilder<FavoriteItem?>(
          stream: _favService.watchEntity(match.matchId),
          builder: (context, snap) {
            final isNotif = snap.data?.notificationsEnabled ?? false;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchDetailsPage(match: match),
                ),
              ),
              child: UtakmicaContainer(
                matchStatus: match.status,
                team1Name: match.homeTeam,
                team2Name: match.awayTeam,
                team1Logo: match.homeTeamLogo,
                team2Logo: match.awayTeamLogo,
                team1Score: match.homeTeamGoals,
                team2Score: match.awayTeamGoals,
                matchTime: _formatMatchTime(match.matchTime),
                isNotificationEnabled: isNotif,
                onNotification: () => _favService.toggleNotification(
                  FavoriteItem(
                    entityId: match.matchId,
                    type: 'match',
                    name: '${match.homeTeam} vs ${match.awayTeam}',
                    imageUrl: '',
                    leagueId: match.leagueCode,
                    leagueName: match.leagueCode,
                    starred: snap.data?.starred ?? false,
                    notificationsEnabled: isNotif,
                    createdAt: DateTime.now(),
                  ),
                ),
              ),
            );
          },
        );
      },
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

  String _formatMatchTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}.${date.month}.${date.year}";
    } catch (_) {
      return dateString;
    }
  }
}
