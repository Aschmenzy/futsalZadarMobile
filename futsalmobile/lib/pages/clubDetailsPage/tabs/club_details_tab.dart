import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/pages/clubDetailsPage/widgets/club_details_next_match.dart';
import 'package:futsalmobile/pages/clubDetailsPage/widgets/trainer_container.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';

class ClubDetailsTab extends StatelessWidget {
  final ClubData clubData;
  final String leagueId;
  const ClubDetailsTab({
    super.key,
    required this.clubData,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenHeight),
        child: ColoredBox(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SponsorsBanner(),

                  SizedBox(height: screenHeight * 0.03),

                  ClubDetailsNextMatch(
                    leaugeId: leagueId,
                    clubName: clubData.clubName,
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.20,
                    color: AppColors.ternaryGray,
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  TrainerContainer(
                    screenHeight: screenHeight,
                    trainer: clubData.trainer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
