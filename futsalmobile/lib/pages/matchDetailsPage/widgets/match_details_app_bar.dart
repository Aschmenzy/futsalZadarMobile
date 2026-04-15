import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';

class MatchDetailsAppBar extends StatelessWidget {
  final MatchData match;

  const MatchDetailsAppBar({super.key, required this.match});

  String _periodLabel(String? period) {
    switch (period) {
      case '1st':
        return 'Prvo poluvrijeme';
      case '2nd':
        return 'Drugo poluvrijeme';
      case 'ot':
        return 'Produžeci';
      default:
        return 'Završeno';
    }
  }

  String get _statusLabel {
    if (match.isLive) {
      return _periodLabel(match.matchState?.currentPeriod);
    }
    if (match.isFinished || match.isAwarded) return 'Završeno';
    if (match.isPostponed) return 'Odgođena';
    if (match.isInterrupted) return 'Utakmica prekinuta';
    final parts = match.matchDate.split('-');
    final formatted = parts.length == 3
        ? '${parts[2]}.${parts[1]}.${parts[0]} ${match.matchTime}'
        : '${match.matchDate} ${match.matchTime}';
    return formatted;
  }

  Color get _statusColor {
    if (match.isLive) return AppColors.liveGame;
    if (match.isPostponed) return AppColors.ternaryGray;
    if (match.isInterrupted) return AppColors.gameInterrupted;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.ternary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: AppColors.secondary,
                ),
                label: Text(
                  'Natrag',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    color: AppColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Teams + score row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Home team
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(match.homeTeamLogo),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Centre: score + status + delegate
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${match.homeTeamGoals} - ${match.awayTeamGoals}',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.w800,
                            fontSize: 25,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _statusLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: _statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Delegat: ${match.delegate}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 10,
                            color: AppColors.ternaryGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Away team
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(match.awayTeamLogo),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _teamLogo(String? logoUrl) {
  if (logoUrl != null && logoUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        logoUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackLogo(),
      ),
    );
  }
  return _fallbackLogo();
}

Widget _fallbackLogo() {
  return Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: AppColors.background,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.ternaryGray.withValues(alpha: 0.4)),
    ),
    child: const Icon(
      Icons.sports_soccer,
      size: 34,
      color: AppColors.ternaryGray,
    ),
  );
}
