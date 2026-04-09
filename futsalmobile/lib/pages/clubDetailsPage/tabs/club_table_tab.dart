import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/widgets/standings_card.dart';

class ClubTableTab extends StatelessWidget {
  final ClubData clubData;
  final String leagueId;
  final String leagueName;
  final String season;

  const ClubTableTab({
    super.key,
    required this.clubData,
    required this.leagueId,
    required this.leagueName,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StandingsCard(
              leagueCode: leagueId,
              leagueName: leagueName,
              leaugeSeason: season,
              highlightedClubId: clubData.id,
            ),
          ),
        ),
      ),
    );
  }
}
