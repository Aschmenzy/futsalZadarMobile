import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/pages/leaguePage/leagueDetails/league_detals.dart';
import 'package:futsalmobile/pages/leaguePage/models/league_data.dart';

class LeaugeContainer extends StatefulWidget {
  const LeaugeContainer({
    super.key,

    required this.leaugeNum,
    required this.leaugeName,
    required this.leaugeID,
  });

  final String leaugeName;
  final String leaugeID;
  final int leaugeNum;

  @override
  State<LeaugeContainer> createState() => _LeaugeContainerState();
}

class _LeaugeContainerState extends State<LeaugeContainer> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final titleFontSize = screenWidth * 0.045;
    final labelFontSize = screenWidth * 0.03;
    final valueFontSize = screenWidth * 0.03;

    final labelIconSize = screenWidth * 0.04;
    final chevronIconSize = screenWidth * 0.06;

    final horizontalPadding = screenWidth * 0.02;
    final verticalSpacing = screenHeight * 0.008;
    final smallSpacing = screenHeight * 0.004;
    final iconTextGap = screenWidth * 0.01;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LeagueDetails(
            league: LeagueData(
              id: widget.leaugeID,
              leagueNumber: widget.leaugeNum,
              clubs: [],
            ),
          ),
        ),
      ),
      child: Container(
        width: screenWidth * 0.85,
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
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            SizedBox(width: horizontalPadding),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.leaugeName,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: verticalSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.blue,
                                  size: labelIconSize,
                                ),
                                SizedBox(width: iconTextGap),
                                Flexible(
                                  child: Text(
                                    "Broj timova:",
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto.fontFamily,
                                      fontSize: labelFontSize,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: smallSpacing),
                            Padding(
                              padding: EdgeInsets.only(
                                left: labelIconSize + iconTextGap,
                              ),
                              child: Text(
                                "12",
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto.fontFamily,
                                  fontSize: valueFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: labelIconSize,
                                ),
                                SizedBox(width: iconTextGap),
                                Flexible(
                                  child: Text(
                                    "Vodeći tim:",
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto.fontFamily,
                                      fontSize: labelFontSize,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: smallSpacing),
                            Padding(
                              padding: EdgeInsets.only(
                                left: labelIconSize + iconTextGap,
                              ),
                              child: Text(
                                "Hajduk",
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto.fontFamily,
                                  fontSize: valueFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
