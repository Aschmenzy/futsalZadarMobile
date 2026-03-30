import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class UtakmicaContainer extends StatelessWidget {
  final String matchStatus;
  final String team1Name;
  final String team2Name;
  final String team1Logo;
  final String team2Logo;
  final int team1Score;
  final int team2Score;
  final String matchTime;
  final String matchDate;

  const UtakmicaContainer({
    super.key,
    this.matchStatus = "scheduled",
    this.team1Name = "Hajduk",
    this.team2Name = "Dinamo",
    this.team1Logo = "assets/images/clubLogo/hajduk.png",
    this.team2Logo = "assets/images/clubLogo/dinamo.png",
    this.team1Score = 2,
    this.team2Score = 0,
    this.matchTime = "25:14",
    this.matchDate = "1.1.2000",
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 0.10,
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.18,
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Status and time row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_buildStatusBadge(screenWidth)],
                ),
                SizedBox(height: screenHeight * 0.005),
                // Team 1 row
                _buildTeamRow(screenWidth, team1Logo, team1Name, team1Score),
                // Team 2 row
                _buildTeamRow(screenWidth, team2Logo, team2Name, team2Score),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the status badge that changes based on match status
  Widget _buildStatusBadge(double screenWidth) {
    if (matchStatus == "ongoing") {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025,
          vertical: screenWidth * 0.008,
        ),
        decoration: BoxDecoration(
          color: AppColors.liveGame,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenWidth * 0.025,
              height: screenWidth * 0.025,
              decoration: BoxDecoration(
                color: AppColors.ternary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              "UŽIVO",
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.ternary,
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (matchStatus == "paused") {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025,
          vertical: screenWidth * 0.008,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentYellow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenWidth * 0.025,
              height: screenWidth * 0.025,
              decoration: BoxDecoration(
                color: AppColors.ternary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              "PAUZA",
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.ternary,
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (matchStatus == "finished") {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025,
          vertical: screenWidth * 0.008,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentYellow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenWidth * 0.025,
              height: screenWidth * 0.025,
              decoration: BoxDecoration(
                color: AppColors.ternary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              "ZAVRŠENO",
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.ternary,
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      // Scheduled status - clock icon
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            color: AppColors.ternaryGray,
            size: screenWidth * 0.06,
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            matchTime,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              color: AppColors.ternaryGray,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ],
      );
    }
  }

  /// Builds a team row with logo, name, and score
  Widget _buildTeamRow(
    double screenWidth,
    String teamLogo,
    String teamName,
    int score,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              SizedBox(
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                child: teamLogo.isNotEmpty
                    ? Image.network(teamLogo, fit: BoxFit.cover)
                    : Image.asset('assets/images/newsImage.png', scale: 0.7),
              ),
              SizedBox(width: screenWidth * 0.03),
              Flexible(
                child: Text(
                  teamName,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    color: Colors.black,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          "$score",
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            color: Colors.black,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
      ],
    );
  }
}
