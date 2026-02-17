import 'package:flutter/material.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/tabs/details_tab.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/tabs/matches_tab.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/tabs/stats_tab.dart';
import 'package:futsalmobile/pages/leaguePage/models/league_data.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_appBar.dart';

class LeagueDetails extends StatefulWidget {
  final LeagueData league;
  const LeagueDetails({super.key, required this.league});

  @override
  State<LeagueDetails> createState() => _LeagueDetailsState();
}

class _LeagueDetailsState extends State<LeagueDetails>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          DetailsTab(league: widget.league),
          MatchesTab(league: widget.league),
          MatchesTab(league: widget.league),
          StatisticsTab(league: widget.league),
        ],
      ),
      appBar: LeagueAppBar(
        leagueName: widget.league.name,
        season: "25/26",
        tabController: _tabController,
      ),
    );
  }
}
