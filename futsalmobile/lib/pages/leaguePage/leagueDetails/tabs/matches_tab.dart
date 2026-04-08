import 'package:flutter/material.dart';
import 'package:futsalmobile/models/league_data.dart';
import 'package:futsalmobile/widgets/matches_list_widget.dart';

class MatchesTab extends StatelessWidget {
  final LeagueData league;
  final String season;

  const MatchesTab({super.key, required this.league, required this.season});

  @override
  Widget build(BuildContext context) {
    return MatchesListWidget(leagueId: league.id, season: season);
  }
}
