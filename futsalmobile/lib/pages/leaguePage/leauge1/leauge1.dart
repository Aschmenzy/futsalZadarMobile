import 'package:flutter/material.dart';
import 'package:futsalmobile/pages/leaguePage/leauge1/tabs/details_tab.dart';
import 'package:futsalmobile/pages/leaguePage/leauge1/tabs/matches_tab.dart';
import 'package:futsalmobile/pages/leaguePage/leauge1/tabs/stats_tab.dart';
import 'package:futsalmobile/pages/leaguePage/leauge1/tabs/table_tab.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_appBar.dart';


class Leauge1 extends StatefulWidget {
  const Leauge1({super.key});

  @override
  State<Leauge1> createState() => _Leauge1State();
}

class _Leauge1State extends State<Leauge1> with SingleTickerProviderStateMixin {
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
      appBar: LeagueAppBar(
        leagueName: '1. futsal liga Zadar',
        season: '25/26',
        tabController: _tabController,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DetailsTab(),
          MatchesTab(),
          TableTab(),
          StatisticsTab(),
          ],
      ),
    );
  }
}
