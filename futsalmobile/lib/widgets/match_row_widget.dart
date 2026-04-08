import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';

/// A single match row.
///
/// Pass a [trailing] widget to render on the right side (e.g. W/D/L badge,
/// notification icon). If null, the trailing slot is left empty.
class MatchRowWidget extends StatelessWidget {
  final MatchData match;
  final Widget? trailing;

  const MatchRowWidget({super.key, required this.match, this.trailing});

  String _formatDate(String matchDate) {
    final parts = matchDate.split('-');
    if (parts.length != 3) return matchDate;
    return '${parts[2]}/${parts[1]}/${parts[0].substring(2)}';
  }

  String _formatTime(String matchDate, String matchTime) {
    final matchDateTime = DateTime.tryParse('$matchDate $matchTime');
    if (matchDateTime == null) return matchTime;
    return matchDateTime.isBefore(DateTime.now()) ? 'FT' : matchTime;
  }

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(match.matchDate);
    final time = _formatTime(match.matchDate, match.matchTime);

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 13,
                    color: AppColors.ternaryGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 13,
                    color: AppColors.ternaryGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 2.5,
            color: AppColors.ternaryGray,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _teamRow(match.homeTeamLogo, match.homeTeam),
                const SizedBox(height: 5),
                _teamRow(match.awayTeamLogo, match.awayTeam),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                match.homeTeamGoals.toString(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                match.awayTeamGoals.toString(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 10),
          VerticalDivider(
            width: 1,
            thickness: 2.5,
            color: AppColors.ternaryGray,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: trailing ?? const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _teamRow(String logo, String name) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.sports, size: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ),
      ],
    );
  }
}
