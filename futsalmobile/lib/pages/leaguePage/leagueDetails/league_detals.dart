import 'package:flutter/material.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/tabs/details_tab.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/tabs/matches_tab.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/tabs/stats_tab.dart';
import 'package:futsalmobile/models/league_data.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/tabs/table_tab.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_appBar.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class LeagueDetails extends StatefulWidget {
  final LeagueData league;
  const LeagueDetails({super.key, required this.league});

  @override
  State<LeagueDetails> createState() => _LeagueDetailsState();
}

class _LeagueDetailsState extends State<LeagueDetails>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _service = FirebaseService();

  String _selectedSeason = '';
  List<String> _seasons = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    try {
      final results = await Future.wait([
        _service.getActiveSeason(),
        _service.getSeasons(),
      ]);
      if (!mounted) return;

      setState(() {
        _selectedSeason = results[0] as String;
        _seasons = results[1] as List<String>;
      });
    } catch (e) {
      debugPrint('Season load error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedSeason.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                DetailsTab(
                  key: ValueKey(_selectedSeason),
                  league: widget.league,
                  season: _selectedSeason,
                ),
                MatchesTab(
                  key: ValueKey(_selectedSeason),
                  league: widget.league,
                  season: _selectedSeason,
                ),
                TableTab(
                  key: ValueKey('table_$_selectedSeason'),
                  league: widget.league,
                  season: _selectedSeason,
                ),
                StatisticsTab(
                  key: ValueKey(_selectedSeason),
                  league: widget.league,
                  season: _selectedSeason,
                ),
              ],
            ),
      appBar: LeagueAppBar(
        leagueName: widget.league.name,
        season: _selectedSeason.isEmpty ? '...' : _selectedSeason,
        seasons: _seasons,
        tabController: _tabController,
        onSeasonChanged: (s) => setState(() => _selectedSeason = s),
      ),
    );
  }
}
