import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';

class NextMatch extends StatelessWidget {
  final MatchData? match;

  const NextMatch({super.key, this.match});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: screenWidth * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: (match == null || _daysDiff(match!.matchDate) < 0)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nema zakazanih utakmica'),
                ),
              )
            : Column(
                children: [
                  // HEADER ROW
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        'Sljedeca utakmica',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // TEAMS ROW — each team gets flex:3, middle gets flex:4
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Home team
                      Expanded(
                        flex: 3,
                        child: _buildTeamColumn(
                          teamName: match!.homeTeam,
                          logoUrl: match!.homeTeamLogo,
                          screenWidth: screenWidth,
                        ),
                      ),

                      // Middle: countdown + date/time
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _daysUntil(match!.matchDate),
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${match!.matchDate.split('-').reversed.join('.')}. ${match!.matchTime}',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: screenWidth * 0.030,
                                color: AppColors.ternaryGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Away team
                      Expanded(
                        flex: 3,
                        child: _buildTeamColumn(
                          teamName: match!.awayTeam,
                          logoUrl: match!.awayTeamLogo,
                          screenWidth: screenWidth,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTeamColumn({
    required String teamName,
    required String logoUrl,
    required double screenWidth,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.network(
            logoUrl,
            width: screenWidth * 0.13,
            height: screenWidth * 0.13,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              radius: screenWidth * 0.065,
              child: const Icon(Icons.sports),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          teamName,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: screenWidth * 0.032,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  int _daysDiff(String matchDate) {
    final date = DateTime.tryParse(matchDate);
    if (date == null) return 0;
    final now = DateTime.now();
    return date.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String _daysUntil(String matchDate) {
    final diff = _daysDiff(matchDate);
    if (diff == 0) return 'Danas';
    if (diff == 1) return 'Sutra';
    return 'Za $diff dana';
  }
}
