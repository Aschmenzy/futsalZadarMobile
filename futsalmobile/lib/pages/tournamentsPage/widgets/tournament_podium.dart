import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/playoff_tie.dart';

/// Winner / runner-up / third place summary shown for finished tournaments.
class TournamentPodium extends StatelessWidget {
  final List<PlayoffTie> ties;
  final bool thirdPlace;

  const TournamentPodium({
    super.key,
    required this.ties,
    required this.thirdPlace,
  });

  PlayoffTie? _tie(bool Function(PlayoffTie) test) {
    try {
      return ties.firstWhere(test);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final finalTie =
        _tie((t) => t.id == 'final' || t.round == 'final');
    final thirdTie =
        _tie((t) => t.id == '3rd_place' || t.round == '3rd_place');

    if (finalTie?.winner == null) return const SizedBox.shrink();

    final winnerId = finalTie!.winner!;
    final winner =
        finalTie.teamA?.clubId == winnerId ? finalTie.teamA : finalTie.teamB;
    final runnerUp =
        finalTie.teamA?.clubId == winnerId ? finalTie.teamB : finalTie.teamA;

    PlayoffTeam? third;
    if (thirdPlace && thirdTie?.winner != null) {
      third = thirdTie!.teamA?.clubId == thirdTie.winner
          ? thirdTie.teamA
          : thirdTie.teamB;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POREDAK',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          _PodiumRow(place: 1, color: Colors.amber, team: winner),
          const SizedBox(height: 6),
          _PodiumRow(place: 2, color: const Color(0xFFB0B7BF), team: runnerUp),
          if (third != null) ...[
            const SizedBox(height: 6),
            _PodiumRow(place: 3, color: const Color(0xFFCD7F32), team: third),
          ],
        ],
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final int place;
  final Color color;
  final PlayoffTeam? team;

  const _PodiumRow({
    required this.place,
    required this.color,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.emoji_events, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          '$place.',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        if (team != null && team!.clubLogo.isNotEmpty) ...[
          ClipOval(
            child: Image.network(
              team!.clubLogo,
              width: 22,
              height: 22,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(width: 22, height: 22),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            team?.clubName ?? 'Nepoznato',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 14,
              fontWeight: place == 1 ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
