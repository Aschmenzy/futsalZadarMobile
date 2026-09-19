import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_event.dart';
import 'package:futsalmobile/pages/matchDetailsPage/widgets/match_player_link.dart';

class MatchEventsWidget extends StatelessWidget {
  final MatchData match;

  const MatchEventsWidget({super.key, required this.match});

  // Newest first: later periods on top, and inside a period the most recent
  // event first, so goals/own goals/cards that just happened lead the list.
  static const _periodOrder = ['penalties', 'ot', '2nd', '1st'];

  @override
  Widget build(BuildContext context) {
    final events = match.matchState?.events;

    // Build event sections
    final sections = <Widget>[];

    if (events != null && events.isNotEmpty) {
      final sorted = [...events]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      int home = 0;
      int away = 0;
      final processed = <_EventWithScore>[];

      for (final e in sorted) {
        if (['goal', 'goal6m', 'goal10m'].contains(e.type)) {
          if (e.team == 'home') {
            home++;
          } else {
            away++;
          }
        } else if (e.type == 'ownGoal') {
          if (e.team == 'home') {
            away++;
          } else {
            home++;
          }
        }
        processed.add(_EventWithScore(e, home, away));
      }

      final byPeriod = <String, List<_EventWithScore>>{};
      for (final item in processed) {
        byPeriod.putIfAbsent(item.event.period, () => []).add(item);
      }

      // Any period the app does not know about still gets rendered, oldest last.
      final periods = [
        ..._periodOrder.where(byPeriod.containsKey),
        ...byPeriod.keys.where((p) => !_periodOrder.contains(p)),
      ];

      for (final period in periods) {
        final list = byPeriod[period]!;
        sections.add(_periodHeader(period));
        for (final item in list.reversed) {
          final row = _buildEventRow(context, item);
          if (row != null) sections.add(row);
        }
      }
    }

    if (sections.isEmpty) {
      if (match.isScheduled) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nema događaja',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              color: AppColors.ternaryGray,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections,
      ),
    );
  }

  // ── Period header ─────────────────────────────────────────────────────────────

  Widget _periodHeader(String period) {
    final label = switch (period) {
      '1st' => 'Prvo poluvrijeme',
      '2nd' => 'Drugo poluvrijeme',
      'ot' => 'Produžeci',
      'penalties' => 'Penali',
      _ => period,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.secondary, thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.secondary, thickness: 1.2)),
        ],
      ),
    );
  }

  // ── Event row ─────────────────────────────────────────────────────────────────

  Widget? _buildEventRow(BuildContext context, _EventWithScore item) {
    final e = item.event;
    final isHome = e.team == 'home';
    final isGoal = ['goal', 'goal6m', 'goal10m', 'ownGoal'].contains(e.type);
    final isCard = e.type == 'yellowCard' || e.type == 'redCard';

    if (!isGoal && !isCard) return null;

    Widget content;

    if (isGoal) {
      final score = '${item.homeGoals} - ${item.awayGoals}';
      final isOwn = e.type == 'ownGoal';
      final name = isOwn ? '${e.playerName} (AG)' : e.playerName;

      content = isHome
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/stats/SoccerBall.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 6),
                Card(
                  elevation: 1,
                  clipBehavior: Clip.antiAlias,
                  color: AppColors.ternary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(5),
                  ),
                  child: Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(5, 2, 5, 2),
                    child: Text(
                      score,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _playerName(
                  context,
                  e,
                  name,
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _playerName(
                  context,
                  e,
                  name,
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Card(
                  elevation: 1,
                  clipBehavior: Clip.antiAlias,
                  color: AppColors.ternary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(5),
                  ),
                  child: Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(5, 2, 5, 2),
                    child: Text(
                      score,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Image.asset(
                  'assets/icons/stats/SoccerBall.png',
                  width: 20,
                  height: 20,
                ),
              ],
            );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _playerName(
            context,
            e,
            e.playerName,
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          _cardIcon(e.type),
        ],
      );
    }

    final minute = e.timeInMatch;
    final minuteText = Text(
      "$minute'",
      style: TextStyle(
        fontFamily: AppFonts.roboto,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ternaryGray,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Align(
        alignment: isHome ? Alignment.centerLeft : Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isHome
              ? [minuteText, const SizedBox(width: 6), content]
              : [content, const SizedBox(width: 6), minuteText],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Player name, tappable when the event carries a player id.
  Widget _playerName(
    BuildContext context,
    MatchEvent event,
    String label,
    TextStyle style,
  ) {
    final text = Text(
      label,
      style: style.copyWith(fontFamily: AppFonts.roboto),
    );
    if (event.playerId.isEmpty) return text;
    return GestureDetector(
      onTap: () => MatchPlayerLink.open(
        context,
        leagueId: match.leagueCode,
        leagueName: match.league,
        teamName: event.team == 'home' ? match.homeTeam : match.awayTeam,
        playerId: event.playerId,
      ),
      child: text,
    );
  }

  Widget _cardIcon(String type) {
    return Image.asset(
      type == 'redCard'
          ? 'assets/icons/stats/Foul.png'
          : 'assets/icons/stats/yellowCard.png',
      width: 22,
      height: 22,
    );
  }
}

class _EventWithScore {
  final MatchEvent event;
  final int homeGoals;
  final int awayGoals;

  _EventWithScore(this.event, this.homeGoals, this.awayGoals);
}
