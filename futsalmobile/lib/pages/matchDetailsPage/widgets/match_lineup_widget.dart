import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_player.dart';
import 'package:futsalmobile/pages/matchDetailsPage/widgets/match_player_link.dart';
import 'package:futsalmobile/widgets/pro_badge.dart';

/// "Sastav" tab — captain, goalkeeper and the full match squad of both teams,
/// with shirt numbers. Tapping a player opens their profile.
class MatchLineupWidget extends StatelessWidget {
  final MatchData match;

  const MatchLineupWidget({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final state = match.matchState;
    final homePlayers = state?.homeTeamPlayers ?? const <MatchPlayer>[];
    final awayPlayers = state?.awayTeamPlayers ?? const <MatchPlayer>[];

    if (homePlayers.isEmpty && awayPlayers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            match.isScheduled
                ? 'Sastavi još nisu objavljeni'
                : 'Sastavi nisu dostupni',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              color: AppColors.ternaryGray,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _teamCard(
            context,
            teamName: match.homeTeam,
            logo: match.homeTeamLogo,
            players: homePlayers,
            shirtNumbers: state?.homeShirtNumbers ?? const {},
            captainId: state?.homeCaptainId,
            goalkeeperId: state?.homeGoalkeeperId,
          ),
          const SizedBox(height: 16),
          _teamCard(
            context,
            teamName: match.awayTeam,
            logo: match.awayTeamLogo,
            players: awayPlayers,
            shirtNumbers: state?.awayShirtNumbers ?? const {},
            captainId: state?.awayCaptainId,
            goalkeeperId: state?.awayGoalkeeperId,
          ),
        ],
      ),
    );
  }

  Widget _teamCard(
    BuildContext context, {
    required String teamName,
    required String logo,
    required List<MatchPlayer> players,
    required Map<String, String> shirtNumbers,
    required String? captainId,
    required String? goalkeeperId,
  }) {
    // Numbered players first in shirt order, unnumbered ones alphabetically.
    final sorted = [...players]..sort((a, b) {
      final na = int.tryParse(shirtNumbers[a.id] ?? '');
      final nb = int.tryParse(shirtNumbers[b.id] ?? '');
      if (na != null && nb != null) return na.compareTo(nb);
      if (na != null) return -1;
      if (nb != null) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _teamHeader(teamName, logo),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Text(
                'Sastav nije objavljen',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13,
                  color: AppColors.ternaryGray,
                ),
              ),
            )
          else
            for (final player in sorted)
              _playerRow(
                context,
                teamName: teamName,
                player: player,
                shirtNumber: shirtNumbers[player.id],
                isCaptain: player.id == captainId,
                isGoalkeeper: player.id == goalkeeperId,
              ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _teamHeader(String teamName, String logo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: logo.isNotEmpty
                  ? Image.network(
                      logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.sports_soccer,
                        size: 18,
                        color: AppColors.ternaryGray,
                      ),
                    )
                  : const Icon(
                      Icons.sports_soccer,
                      size: 18,
                      color: AppColors.ternaryGray,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerRow(
    BuildContext context, {
    required String teamName,
    required MatchPlayer player,
    required String? shirtNumber,
    required bool isCaptain,
    required bool isGoalkeeper,
  }) {
    return InkWell(
      onTap: () => MatchPlayerLink.open(
        context,
        leagueId: match.leagueCode,
        leagueName: match.league,
        teamName: teamName,
        playerId: player.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            _shirtNumber(shirtNumber),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (player.isProfessional) ...[
              const SizedBox(width: 6),
              const ProBadge(fontSize: 8),
            ],
            if (isGoalkeeper) ...[
              const SizedBox(width: 6),
              _roleBadge(Icons.sports_handball, 'Golman'),
            ],
            if (isCaptain) ...[
              const SizedBox(width: 6),
              _roleBadge(Icons.star_rounded, 'Kapetan'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shirtNumber(String? number) {
    final label = (number == null || number.trim().isEmpty)
        ? '-'
        : number.trim();
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _roleBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
