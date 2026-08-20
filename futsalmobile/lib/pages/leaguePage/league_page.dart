import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/clubStanding.dart';
import 'package:futsalmobile/models/tournament/tournament_data.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leading_teams.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_container.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/playoff_container.dart';
import 'package:futsalmobile/pages/tournamentsPage/tournament_archive_page.dart';
import 'package:futsalmobile/pages/tournamentsPage/widgets/tournament_container.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class LeaguePage extends StatefulWidget {
  const LeaguePage({super.key});

  @override
  State<LeaguePage> createState() => _LeaguePageState();
}

class _LeaguePageState extends State<LeaguePage> {
  final _service = FirebaseService();
  final Map<String, int> _clubCounts = {};
  final Map<String, ClubStanding?> _leadingClubs = {};
  List<TournamentData> _activeTournaments = [];
  bool _hasArchivedTournaments = false;
  StreamSubscription? _invalidationSub;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadTournaments();
    _invalidationSub = _service.onCacheInvalidated.listen((_) {
      // Consume both flags before the mounted check — they are one-shot, and
      // short-circuiting would leave the second one set for nobody to read.
      final playoffDirty = _service.consumePlayoffCacheDirty();
      final tournamentsDirty = _service.consumeTournamentsCacheDirty();
      if (!mounted) return;
      if (playoffDirty) setState(() {});
      // The Hive entry was already cleared by the service, so this re-fetches.
      if (tournamentsDirty) _loadTournaments();
    });
  }

  Future<void> _loadTournaments() async {
    try {
      final tournaments = await _service.getTournaments();
      if (!mounted) return;
      setState(() {
        _activeTournaments = tournaments.where((t) => t.isActive).toList();
        _hasArchivedTournaments = tournaments.any((t) => !t.isActive);
      });
    } catch (_) {
      // Tournaments are optional — keep the page functional without them.
    }
  }

  @override
  void dispose() {
    _invalidationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    for (final id in ['liga1', 'liga2', 'liga3', 'liga4']) {
      final count = await _service.getClubCount(id);
      setState(() => _clubCounts[id] = count);
    }

    for (final id in ['liga1', 'liga2', 'liga3', 'liga4']) {
      final club = await _service.getBestClubInLeague(id);
      setState(() => _leadingClubs[id] = club);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', height: 107),
                  ),
                  SizedBox(height: 40),

                  if (_service.cachedPlayoffInfo.hasAny) ...[
                    Text(
                      'Nadigravanje',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_service.cachedPlayoffInfo.hasLiga1) ...[
                      PlayoffContainer(
                        leagueId: 'liga1',
                        displayName: 'Liga 1',
                      ),
                      SizedBox(height: 12),
                    ],
                    for (final group in _service.cachedPlayoffInfo.ligaskaGroups) ...[
                      PlayoffContainer(
                        leagueId: group.id,
                        displayName: group.label,
                        isGroup: true,
                      ),
                      SizedBox(height: 12),
                    ],
                    SizedBox(height: 16),
                  ],

                  if (_activeTournaments.isNotEmpty) ...[
                    Text(
                      'Turniri',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 12),
                    for (final tournament in _activeTournaments) ...[
                      TournamentContainer(tournament: tournament),
                      SizedBox(height: 12),
                    ],
                    SizedBox(height: 16),
                  ],

                  Text(
                    'Lige',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 12),

                  LeaugeContainer(
                    leaugeNum: 1,
                    leaugeName: 'Liga 1',
                    leaugeID: 'liga1',
                    numOfClubs: _clubCounts["liga1"],
                    leadingTeam: _leadingClubs["liga1"],
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 2,
                    leaugeName: 'Liga 2',
                    leaugeID: 'liga2',
                    numOfClubs: _clubCounts["liga2"],
                    leadingTeam: _leadingClubs["liga2"],
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 3,
                    leaugeName: 'Liga 3',
                    leaugeID: 'liga3',
                    numOfClubs: _clubCounts["liga3"],
                    leadingTeam: _leadingClubs["liga3"],
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 4,
                    leaugeName: 'Liga 4',
                    leaugeID: 'liga4',
                    numOfClubs: _clubCounts["liga4"],
                    leadingTeam: _leadingClubs["liga4"],
                  ),

                  SizedBox(height: 20),

                  if (_hasArchivedTournaments) ...[
                    _ArchiveTile(),
                    SizedBox(height: 20),
                  ],

                  //vodeci timpovi po ligama PLACE HOLDER
                  LeadingTeams(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact tile linking to the tournament archive.
class _ArchiveTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TournamentArchivePage()),
      ),
      child: Card(
        elevation: 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  color: AppColors.secondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Arhiva turnira',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
