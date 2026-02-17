import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';
import 'package:futsalmobile/pages/leaguePage/models/league_data.dart';

class DetailsTab extends StatelessWidget {
  final LeagueData league;
  const DetailsTab({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: AppColors.background),
          child: Column(
            children: [
              SponsorsBanner(),
              SizedBox(height: screenHeight * 0.02),

              // Liga progress card
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: screenWidth * 0.85,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ternary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 44,
                        height: 44,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${league.name}, Runda ${league.currentRound}',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: league.currentRound / 22,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "",
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto.fontFamily,
                                    fontSize: 12,
                                    color: AppColors.ternaryGray,
                                  ),
                                ),
                                Text(
                                  "dateFormat.format(LeagueData.endDate)",
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto.fontFamily,
                                    fontSize: 12,
                                    color: AppColors.ternaryGray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Sljedeca utakmica card
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: screenWidth * 0.85,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ternary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            "Sljedeca utakmica",
                            style: TextStyle(
                              fontFamily: AppFonts.roboto.fontFamily,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTeamColumn(
                            teamName: "Hajduk",
                            logoPath: 'assets/images/clubLogo/hajduk.png',
                          ),
                          Column(
                            children: [
                              Text(
                                "Za 7 dana",
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "18.01.2026. 19:00",
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto.fontFamily,
                                  fontSize: 13,
                                  color: AppColors.ternaryGray,
                                ),
                              ),
                            ],
                          ),
                          _buildTeamColumn(
                            teamName: "Dinamo",
                            logoPath: 'assets/images/logo_withBg.png',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Broj ekipa card
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: screenWidth * 0.85,
                  height: screenHeight * 0.08,
                  decoration: BoxDecoration(
                    color: AppColors.ternary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Broj ekipa",
                        style: TextStyle(
                          fontFamily: AppFonts.roboto.fontFamily,
                          color: AppColors.ternaryGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        '${league.teamCount}',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Visa liga
              if (league.higherLeagueName != null)
                _buildRelatedLeagueCard(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  label: "Viša liga",
                  leagueName: league.higherLeagueName!,
                ),
              // Niza liga
              if (league.lowerLeagueName != null)
                _buildRelatedLeagueCard(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  label: "Niža liga",
                  leagueName: league.lowerLeagueName!,
                ),

              SizedBox(height: screenHeight * 0.01),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamColumn({
    required String teamName,
    required String logoPath,
  }) {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            logoPath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          teamName,
          style: TextStyle(
            fontFamily: AppFonts.roboto.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedLeagueCard({
    required double screenWidth,
    required double screenHeight,
    required String label,
    required String leagueName,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: screenWidth * 0.85,
          height: screenHeight * 0.09,
          decoration: BoxDecoration(
            color: AppColors.ternary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', scale: 2),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      leagueName,
                      style: TextStyle(fontFamily: AppFonts.roboto.fontFamily),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
