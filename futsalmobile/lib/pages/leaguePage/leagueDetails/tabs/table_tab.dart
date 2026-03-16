import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/league_data.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/standings_card.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';

class TableTab extends StatelessWidget {
  final LeagueData league;
  final String season;

  const TableTab({super.key, required this.league, required this.season});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SponsorsBanner(),

                SizedBox(height: 20),

                StandingsCard(
                  leagueCode: league.id,
                  leagueName: league.name,
                  leaugeSeason: season,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
