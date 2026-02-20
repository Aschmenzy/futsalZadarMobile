import 'package:flutter/material.dart';
import 'package:futsalmobile/models/league_data.dart';

class StatisticsTab extends StatelessWidget {
  final LeagueData league;
  const StatisticsTab({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Statistika'));
  }
}
