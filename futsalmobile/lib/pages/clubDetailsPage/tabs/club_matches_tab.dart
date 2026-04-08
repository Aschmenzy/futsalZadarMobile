import 'package:flutter/material.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/widgets/matches_list_widget.dart';

class ClubMatchesTab extends StatelessWidget {
  final ClubData clubData;
  final String leagueId;
  final String season;

  const ClubMatchesTab({
    super.key,
    required this.clubData,
    required this.leagueId,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    return MatchesListWidget(
      leagueId: leagueId,
      season: season,
      clubFilter: clubData.clubName,
    );
  }
}
