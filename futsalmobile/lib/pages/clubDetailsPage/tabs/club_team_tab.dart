import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/pages/clubDetailsPage/widgets/trainer_container.dart';

class ClubTeamTab extends StatelessWidget {
  final ClubData clubData;

  const ClubTeamTab({super.key, required this.clubData});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TrainerContainer(
                    screenHeight: screenHeight,
                    trainer: clubData.trainer,
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.5,
                    color: AppColors.ternaryGray,
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
