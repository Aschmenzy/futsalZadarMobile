import 'dart:async';

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

bool isRunningStatus(String status) =>
    status == 'ongoing' || status == 'paused';

/// Live and paused first, then not yet started, then everything that is
/// over (finished, awarded, postponed, interrupted).
int _statusRank(String status) {
  if (isRunningStatus(status)) return 0;
  if (status == 'scheduled') return 1;
  return 2;
}

/// Orders one day's matches: live → upcoming → finished, each by kickoff.
/// [statusOf] lets the page supply a fresher status than the list's.
void sortDayMatches(
  List<MatchData> matches, {
  String Function(MatchData)? statusOf,
}) {
  final status = statusOf ?? (MatchData m) => m.status;
  matches.sort((a, b) {
    final byStatus = _statusRank(status(a)).compareTo(_statusRank(status(b)));
    if (byStatus != 0) return byStatus;
    return MatchData.byKickoff(a, b);
  });
}

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

  /// Latest Firestore status of the selected day's running matches. A match
  /// finishing doesn't refresh the list right away, so this keeps the order
  /// (live → upcoming → finished) correct while the page is open.
  final Map<String, String> _liveStatus = {};
  final Map<String, StreamSubscription<MatchData>> _liveSubs = {};

  @override
  void initState() {
    super.initState();
    _matchesStream = _service.getUpcomingMatchesStream();
  }

  @override
  void dispose() {
    for (final sub in _liveSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  String _statusOf(MatchData m) => _liveStatus[m.matchId] ?? m.status;

  /// Listens to the day's running matches so a status change re-sorts the
  /// list. Shares the Firestore listener with the live cards' StreamBuilders.
  void _watchRunning(List<MatchData> dayMatches) {
    final running = {
      for (final m in dayMatches)
        if (isRunningStatus(m.status)) m.matchId: m,
    };
    for (final id in _liveSubs.keys.toList()) {
      if (!running.containsKey(id)) _liveSubs.remove(id)!.cancel();
    }
    for (final m in running.values) {
      _liveSubs[m.matchId] ??= _service.watchMatch(m).listen((fresh) {
        if (!mounted || _statusOf(m) == fresh.status) return;
        setState(() => _liveStatus[m.matchId] = fresh.status);
      }, onError: (_) {});
    }
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
            child: StreamBuilder<List<MatchData>>(
              stream: _matchesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  _cachedMatches = snapshot.data!;
                }
                final matches = _cachedMatches;
                final hasMatches = matches != null && matches.isNotEmpty;

                Widget listArea;
                if (hasMatches) {
                  listArea = _buildMatchesList(matches, _selectedDate);
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  listArea = Center(
                    child: ShimmerLoading(
                      width: double.infinity,
                      height: screenHeight * 0.18,
                    ),
                  );
                } else if (snapshot.hasError) {
                  listArea = Center(
                    child: Text('Greška pri učitavanju utakmica'),
                  );
                } else {
                  listArea = Center(child: Text('Nema dostupnih utakmica'));
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset('assets/images/logo.png', height: 107),
                    ),

                    SizedBox(height: screenHeight * 0.035),

                    CalendarCard(
                      currentDate: _selectedDate,
                      matchDays: _matchDays(matches),
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

                    Expanded(child: listArea),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Days (normalized to y/m/d) that have at least one match, so the calendar
  /// can mark them with a dot. Derived from the matches already in memory —
  /// no extra fetch.
  Set<DateTime> _matchDays(List<MatchData>? matches) {
    if (matches == null) return const {};
    final days = <DateTime>{};
    for (final match in matches) {
      if (match.matchDate.isEmpty) continue;
      final date = DateTime.tryParse(match.matchDate);
      if (date == null) continue;
      days.add(DateTime(date.year, date.month, date.day));
    }
    return days;
  }

  Widget _buildMatchesList(List<MatchData> matches, DateTime selectedDate) {
    final filtered = _filterMatchesByDate(matches, selectedDate);
    // A newer list fetch is the source of truth again; only keep live
    // statuses for matches the list still shows as running.
    _liveStatus.removeWhere(
      (id, _) =>
          !filtered.any((m) => m.matchId == id && isRunningStatus(m.status)),
    );
    _watchRunning(filtered);
    sortDayMatches(filtered, statusOf: _statusOf);

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
        final playoffLabel = _service.playoffMatchLabels[match.matchId];

        Widget card;
        if (match.isLive || match.status == 'paused') {
          card = StreamBuilder<MatchData>(
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
                  matchTime: _formatMatchTime(m.matchTime),
                ),
              );
            },
          );
        } else if (match.status != 'scheduled') {
          card = GestureDetector(
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
              matchTime: _formatMatchTime(match.matchTime),
            ),
          );
        } else if (playoffLabel != null) {
          // Playoff matches — no notification bell
          card = GestureDetector(
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
              matchTime: _formatMatchTime(match.matchTime),
              showMatchDate: true,
              matchDate: match.matchDate,
            ),
          );
        } else {
          // Scheduled matches get notification bell via StreamBuilder
          card = StreamBuilder<FavoriteItem?>(
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
                  footballArena: match.footballArena,
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
        }

        if (playoffLabel != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  playoffLabel,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              card,
            ],
          );
        }
        return card;
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
