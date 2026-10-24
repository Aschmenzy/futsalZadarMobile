import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/news/news_data.dart';
import 'package:futsalmobile/pages/legal/legal_page.dart';
import 'package:futsalmobile/pages/matchDetailsPage/match_details_page.dart';
import 'package:futsalmobile/pages/newsDetails/news_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/utils/match_order.dart';
import 'package:futsalmobile/widgets/news_container.dart';
import 'package:futsalmobile/widgets/search_bar_widget.dart';
import 'package:futsalmobile/widgets/shimmer_loading.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';
import 'package:futsalmobile/widgets/utakmica_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = FirebaseService();

  late Stream<List<MatchData>> _matchesStream;
  List<MatchData>? _cachedMatches;
  StreamSubscription? _invalidationSub;

  /// Drops a "live" match from the list as soon as its doc says it ended,
  /// even if the API list still reports it as ongoing.
  late final _live = LiveStatusTracker(() {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _matchesStream = _service.getUpcomingMatchesStream();

    // When the admin bumps lastUpdatedMatches, dispose the existing Firestore
    // listener and create a fresh one so new matches appear immediately.
    _invalidationSub = _service.onCacheInvalidated.listen((_) {
      _service.disposeMatchesStream();
      if (mounted) {
        setState(() {
          _cachedMatches = null;
          _matchesStream = _service.getUpcomingMatchesStream();
        });
      }
    });
  }

  @override
  void dispose() {
    _invalidationSub?.cancel();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Image.asset('assets/images/logo.png', height: 107),
                      ),
                      // Permanent entry point for Terms of Service & Privacy Policy
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          tooltip: 'Pravne informacije',
                          icon: const Icon(
                            Icons.info_outline,
                            color: AppColors.ternaryGray,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalPage(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  const AppSearchBar(),
                  SizedBox(height: 16),
                  SponsorsBanner(),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        "Utakmice",
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  StreamBuilder<List<MatchData>>(
                    stream: _matchesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Show cached data while loading if available
                        if (_cachedMatches != null &&
                            _cachedMatches!.isNotEmpty) {
                          return _buildMatchesList(_cachedMatches!);
                        }
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        // Show cached data if available, even with error
                        if (_cachedMatches != null &&
                            _cachedMatches!.isNotEmpty) {
                          return _buildMatchesList(_cachedMatches!);
                        }
                        return Center(
                          child: Text(
                            'Greška pri učitavanju utakmica',
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        // Show cached data if no new data available
                        if (_cachedMatches != null &&
                            _cachedMatches!.isNotEmpty) {
                          return _buildMatchesList(_cachedMatches!);
                        }
                        return Center(child: Text('Nema dostupnih utakmica'));
                      }

                      // Update cache with new data
                      _cachedMatches = snapshot.data!;

                      return _buildMatchesList(_cachedMatches!);
                    },
                  ),
                  SizedBox(height: 20),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    children: [
                      Text(
                        "Najnovija vijest",
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  FutureBuilder<NewsData?>(
                    future: _service.getLatestNews(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ShimmerLoading(
                          width: double.infinity,
                          height: screenHeight * 0.18,
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Center(
                          child: Text(
                            'Nema vijesti',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              color: AppColors.ternaryGray,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      final news = snapshot.data!;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewsDetailsPage(
                              header: news.header,
                              body: news.body,
                              imageUrl: news.imageUrl,
                              date: news.createdAt,
                            ),
                          ),
                        ),
                        child: NewsContainer(
                          header: news.header,
                          body: news.body,
                          imageUrl: news.imageUrl,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build matches list from cached or new data
  Widget _buildMatchesList(List<MatchData> matches) {
    _live.watch(matches);
    final filtered = _filterMatchesClosestToDate(
      matches,
      DateTime.now().toIso8601String(),
    );

    return Column(
      children: [
        for (int i = 0; i < filtered.length && i < 4; i++) ...[
          _buildMatchTile(filtered[i]),
          if (i < 3) SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildMatchTile(MatchData match) {
    if (isRunningStatus(match.status)) {
      return StreamBuilder<MatchData>(
        stream: _service.watchMatch(match),
        initialData: match,
        builder: (context, snap) {
          final m = snap.data ?? match;
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MatchDetailsPage(match: m)),
            ),
            child: UtakmicaContainer(
              matchStatus: m.status,
              team1Name: m.homeTeam,
              team2Name: m.awayTeam,
              team1Logo: m.homeTeamLogo,
              team2Logo: m.awayTeamLogo,
              team1Score: m.homeTeamGoals,
              team2Score: m.awayTeamGoals,
              footballArena: m.footballArena,
              matchTime: m.matchTime,
            ),
          );
        },
      );
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchDetailsPage(match: match)),
      ),
      child: UtakmicaContainer(
        matchStatus: match.status,
        team1Name: match.homeTeam,
        team2Name: match.awayTeam,
        team1Logo: match.homeTeamLogo,
        team2Logo: match.awayTeamLogo,
        team1Score: match.homeTeamGoals,
        team2Score: match.awayTeamGoals,
        footballArena: match.footballArena,
        matchTime: match.matchTime,
        // Home mixes days (next matches can be days away), so show the date.
        showMatchDate: true,
        matchDate: match.matchDate,
      ),
    );
  }

  List<MatchData> _filterMatchesClosestToDate(
    List<MatchData> matches,
    String referenceDate,
  ) {
    if (matches.isEmpty) return [];

    final List<MatchData> liveMatches = [];
    final List<MatchData> upcomingMatches = [];

    final referenceDateParsed = _parseMatchDate(referenceDate);

    for (final match in matches) {
      final status = _live.statusOf(match);
      if (isRunningStatus(status)) {
        liveMatches.add(match);
      } else if (status == 'scheduled' && match.matchDate.isNotEmpty) {
        final matchDateTime = _parseMatchDate(match.matchDate);
        if (matchDateTime.isAfter(referenceDateParsed) ||
            _isSameDay(matchDateTime, referenceDateParsed)) {
          upcomingMatches.add(match);
        }
      }
    }

    // Closest first — by date, then kickoff time within the day.
    sortDayMatches(liveMatches);
    sortDayMatches(upcomingMatches);

    // Return live matches first, then closest upcoming matches
    return [...liveMatches, ...upcomingMatches].take(2).toList();
  }

  /// Parse matchDate - handles "2026-03-29" format
  DateTime _parseMatchDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
