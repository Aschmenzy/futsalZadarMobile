import 'package:flutter/material.dart';
import 'package:futsalmobile/widgets/cached_image.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_official.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_player.dart';
import 'package:futsalmobile/pages/matchDetailsPage/widgets/match_player_link.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/pro_badge.dart';

/// "Sastav" tab — captain, goalkeeper and the full match squad of both teams,
/// with shirt numbers, followed by the team's trainer and voditelj. Tapping a
/// player opens their profile.
class MatchLineupWidget extends StatefulWidget {
  final MatchData match;

  const MatchLineupWidget({super.key, required this.match});

  @override
  State<MatchLineupWidget> createState() => _MatchLineupWidgetState();
}

class _MatchLineupWidgetState extends State<MatchLineupWidget> {
  /// Clubs of the match's league — staff names come from here, since the
  /// match sheet only records the officials' role, attendance and cards.
  late final Future<List<ClubData>> _clubs = widget.match.leagueCode.isEmpty
      ? Future.value(const <ClubData>[])
      : FirebaseService()
            .getClubsByLeague(widget.match.leagueCode)
            .catchError((_) => const <ClubData>[]);

  MatchData get match => widget.match;

  static String _nameKey(String name) => name.trim().toLowerCase();

  ClubData? _clubFor(List<ClubData> clubs, String teamName) => clubs
      .where((c) => _nameKey(c.clubName) == _nameKey(teamName))
      .firstOrNull;

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
            officials: match.homeOfficials,
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
            officials: match.awayOfficials,
          ),
        ],
      ),
    );
  }

  /// Trainer and voditelj rows for one team. A staff member marked absent on
  /// the match sheet is left out; the name falls back to the club record.
  Widget _staffSection(String teamName, List<MatchOfficial> officials) {
    return FutureBuilder<List<ClubData>>(
      future: _clubs,
      builder: (context, snap) {
        final club = _clubFor(snap.data ?? const [], teamName);
        final rows = <Widget>[];
        for (final (role, label, clubName) in [
          ('trainer', 'Trener', club?.trainer ?? ''),
          ('voditelj', 'Voditelj', club?.teamLead ?? ''),
        ]) {
          final entry = officials.where((o) => o.role == role).firstOrNull;
          if (entry != null && !entry.present) continue;
          final name = (entry?.name.isNotEmpty ?? false)
              ? entry!.name
              : clubName.trim();
          if (name.isEmpty) continue;
          rows.add(_staffRow(label, name, entry));
        }
        if (rows.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 12, indent: 14, endIndent: 14),
            ...rows,
          ],
        );
      },
    );
  }

  Widget _staffRow(String label, String name, MatchOfficial? entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ternaryGray,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if ((entry?.yellowCards ?? 0) > 0) ...[
            const SizedBox(width: 6),
            _cardMark(const Color(0xFFF5C518)),
          ],
          if ((entry?.redCards ?? 0) > 0) ...[
            const SizedBox(width: 6),
            _cardMark(const Color(0xFFE53935)),
          ],
        ],
      ),
    );
  }

  Widget _cardMark(Color color) {
    return Container(
      width: 9,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
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
    required List<MatchOfficial> officials,
  }) {
    // Numbered players first in shirt order, unnumbered ones alphabetically.
    final sorted = [...players]
      ..sort((a, b) {
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
          _staffSection(teamName, officials),
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
                  ? CachedImage(
                      logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_) => const Icon(
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
