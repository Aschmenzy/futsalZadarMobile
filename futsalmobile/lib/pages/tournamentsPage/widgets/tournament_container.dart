import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/tournament/tournament_data.dart';
import 'package:futsalmobile/pages/tournamentsPage/tournament_details_page.dart';

/// League-page tile for an active tournament (mirrors PlayoffContainer).
class TournamentContainer extends StatelessWidget {
  final TournamentData tournament;

  const TournamentContainer({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final titleFontSize = screenWidth * 0.045;
    final labelFontSize = screenWidth * 0.03;
    final horizontalPadding = screenWidth * 0.02;
    final verticalSpacing = screenHeight * 0.008;
    final labelIconSize = screenWidth * 0.04;
    final chevronIconSize = screenWidth * 0.06;
    final iconTextGap = screenWidth * 0.01;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDetailsPage(tournament: tournament),
        ),
      ),
      child: Card(
        elevation: 1,
        child: Container(
          width: double.infinity,
          height: screenHeight * 0.12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: horizontalPadding),
              SizedBox(
                width: screenHeight * 0.08,
                height: screenHeight * 0.08,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: horizontalPadding),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: verticalSpacing),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: AppColors.accent,
                          size: labelIconSize,
                        ),
                        SizedBox(width: iconTextGap),
                        Text(
                          'Turnir • ${tournament.bracketSize} momčadi',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: labelFontSize,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: horizontalPadding),
              Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: chevronIconSize,
              ),
              SizedBox(width: horizontalPadding),
            ],
          ),
        ),
      ),
    );
  }
}
