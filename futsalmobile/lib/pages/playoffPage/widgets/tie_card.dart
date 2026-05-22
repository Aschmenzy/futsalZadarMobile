import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/playoff_tie.dart';

/// A card representing a single playoff tie (matchup between two teams).
///
/// Variants:
/// - Normal: shows teamA and teamB rows with optional scores.
/// - Bye: shows only teamA row with an orange "slobodan prolaz" badge.
/// - TBD: shows placeholder circle + italic label for unknown team slots.
class TieCard extends StatelessWidget {
  final PlayoffTeam? teamA;
  final PlayoffTeam? teamB;
  final String teamATbdLabel;
  final String teamBTbdLabel;
  final bool showByeBadge;
  final int? scoreA;
  final int? scoreB;
  final bool isWinnerA;
  final bool isWinnerB;
  final double width;
  final VoidCallback? onTap;

  const TieCard({
    super.key,
    this.teamA,
    this.teamB,
    this.teamATbdLabel = 'TBD',
    this.teamBTbdLabel = 'TBD',
    this.showByeBadge = false,
    this.scoreA,
    this.scoreB,
    this.isWinnerA = false,
    this.isWinnerB = false,
    this.width = double.infinity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 1,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeamRow(
                  team: teamA,
                  tbdLabel: teamATbdLabel,
                  score: scoreA,
                  showScore: scoreA != null && scoreB != null,
                  isWinner: isWinnerA,
                ),
                if (showByeBadge) ...[
                  const SizedBox(height: 4),
                  _ByeBadge(),
                ] else ...[
                  const Divider(height: 8, thickness: 0.5),
                  _TeamRow(
                    team: teamB,
                    tbdLabel: teamBTbdLabel,
                    score: scoreB,
                    showScore: scoreA != null && scoreB != null,
                    isWinner: isWinnerB,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final PlayoffTeam? team;
  final String tbdLabel;
  final int? score;
  final bool showScore;
  final bool isWinner;

  const _TeamRow({
    required this.team,
    required this.tbdLabel,
    this.score,
    this.showScore = false,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    if (team == null) {
      // TBD slot
      return Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tbdLabel,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _TeamLogo(url: team!.clubLogo),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team!.clubName,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
              color: isWinner ? AppColors.primary : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showScore && score != null)
          Text(
            '$score',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
              color: isWinner ? AppColors.primary : Colors.black54,
            ),
          ),
        const SizedBox(width: 2),
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String url;
  const _TeamLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 20,
        height: 20,
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.sports, size: 12, color: Colors.grey.shade400),
    );
  }
}

class _ByeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'slobodan prolaz',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.orange.shade800,
        ),
      ),
    );
  }
}
