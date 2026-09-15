import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';

/// Waypoint icon + "Dvorana: ..." label, centred. Used on match headers and
/// "next match" cards.
class ArenaLabel extends StatelessWidget {
  final String? footballArena;
  final double fontSize;
  final double iconSize;

  const ArenaLabel({
    super.key,
    required this.footballArena,
    this.fontSize = 12,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: iconSize,
          color: AppColors.ternaryGray,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            MatchData.arenaLabelFor(footballArena),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: fontSize,
              color: AppColors.ternaryGray,
            ),
          ),
        ),
      ],
    );
  }
}
