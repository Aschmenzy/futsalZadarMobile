import 'package:flutter/material.dart';
import 'package:futsalmobile/pages/leaguePage/models/league_data.dart';

class MatchesTab extends StatelessWidget {
  final LeagueData league;
  const MatchesTab({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Utakmice'));
  }
}
