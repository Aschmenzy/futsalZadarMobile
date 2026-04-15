import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_event.dart';

class MatchEventsWidget extends StatelessWidget {
  final MatchData match;

  const MatchEventsWidget({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final events = match.matchState?.events;

    if (events == null || events.isEmpty) {
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

    // Sort by timestamp, then compute running score
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
        // Own goal counts for the opponent
        if (e.team == 'home') {
          away++;
        } else {
          home++;
        }
      }
      processed.add(_EventWithScore(e, home, away));
    }

    // Group by period in defined order
    const periodOrder = ['1st', '2nd'];
    final byPeriod = <String, List<_EventWithScore>>{};
    for (final item in processed) {
      byPeriod.putIfAbsent(item.event.period, () => []).add(item);
    }

    final sections = <Widget>[];
    for (final period in periodOrder) {
      final list = byPeriod[period];
      if (list == null) continue;
      sections.add(_periodHeader(period));
      for (final item in list) {
        final row = _buildEventRow(item);
        if (row != null) sections.add(row);
      }
    }

    if (sections.isEmpty) return const SizedBox.shrink();

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

  Widget? _buildEventRow(_EventWithScore item) {
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
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
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
      // Card event
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            e.playerName,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          _cardIcon(e.type),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Align(
        alignment: isHome ? Alignment.centerLeft : Alignment.centerRight,
        child: content,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

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
