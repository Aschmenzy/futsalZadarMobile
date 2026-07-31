import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/pages/playoffPage/widgets/tie_card.dart';

const double _colW = 168.0;
const double _connW = 24.0;
const double _baseSlotH = 84.0;
const double _headerH = 28.0;

/// Generic knockout bracket for tournaments with 4–64 teams.
///
/// Reads the tie documents from tournaments/{id}/ties (qf_0…qf_3, sf_0, sf_1,
/// final, 3rd_place, and analogous prefixes for larger brackets) and renders
/// one column per round, left → right, with connector lines between rounds.
/// Missing ties render as TBD placeholders so the bracket fills in
/// progressively as rounds are created/completed.
class TournamentBracketWidget extends StatelessWidget {
  final int bracketSize;
  final bool thirdPlace;
  final List<PlayoffTie> ties;

  const TournamentBracketWidget({
    super.key,
    required this.bracketSize,
    required this.thirdPlace,
    required this.ties,
  });

  int get _numRounds => bracketSize <= 1 ? 0 : (math.log(bracketSize) / math.ln2).round();

  /// Number of ties in round [level] (0 = first round).
  int _tiesInRound(int level) => bracketSize >> (level + 1);

  /// Round level for a round containing [count] ties, or -1 if invalid.
  int _levelForCount(int count) {
    if (count <= 0 || bracketSize % (count * 2) != 0) return -1;
    final level = (math.log(bracketSize / count) / math.ln2).round() - 1;
    return (level >= 0 && level < _numRounds) ? level : -1;
  }

  /// Resolves which round a tie belongs to from its doc id / round field.
  /// Returns (level, slotIndex) or null for the 3rd-place tie / unknown docs.
  (int, int)? _placeTie(PlayoffTie tie) {
    final id = tie.id;
    if (id == '3rd_place' || tie.round == '3rd_place') return null;
    if (id == 'final' || tie.round == 'final') return (_numRounds - 1, 0);

    // Split "qf_0" → prefix "qf", slot 0
    final sep = id.lastIndexOf('_');
    if (sep <= 0) return null;
    final slot = int.tryParse(id.substring(sep + 1));
    if (slot == null) return null;
    final prefix = id.substring(0, sep);

    // Doc-id prefix first; unknown prefixes fall back to the round field.
    final tieCount = _tieCountFor(prefix) ?? _tieCountFor(tie.round);
    if (tieCount == null) return null;

    final level = _levelForCount(tieCount);
    if (level < 0 || slot >= tieCount) return null;
    return (level, slot);
  }

  /// Number of ties in the round named by [name] ("qf", "sf", "r16", …),
  /// or null if unrecognized.
  int? _tieCountFor(String name) {
    if (name == 'sf') return 2;
    if (name == 'qf') return 4;
    // "r16" / "ro32" style — digits are the number of teams in the round
    final digits = RegExp(r'\d+').firstMatch(name)?.group(0);
    return digits != null ? int.parse(digits) ~/ 2 : null;
  }

  String _roundLabel(int tieCount) {
    switch (tieCount) {
      case 1:
        return 'FINALE';
      case 2:
        return 'POLUFINALE';
      case 4:
        return 'ČETVRTFINALE';
      case 8:
        return 'OSMINA FINALA';
      case 16:
        return 'ŠESNAESTINA FINALA';
      default:
        return '1. KOLO';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_numRounds == 0) {
      return const Center(child: Text('Ždrijeb nije dostupan'));
    }

    // rounds[level][slot] → tie or null
    final rounds = List.generate(
      _numRounds,
      (level) => List<PlayoffTie?>.filled(_tiesInRound(level), null),
    );
    PlayoffTie? thirdPlaceTie;

    for (final tie in ties) {
      if (tie.id == '3rd_place' || tie.round == '3rd_place') {
        thirdPlaceTie = tie;
        continue;
      }
      final pos = _placeTie(tie);
      if (pos != null) rounds[pos.$1][pos.$2] = tie;
    }

    final finalTie = rounds[_numRounds - 1][0];
    PlayoffTeam? champion;
    if (finalTie?.winner != null) {
      final id = finalTie!.winner!;
      champion = finalTie.teamA?.clubId == id ? finalTie.teamA : finalTie.teamB;
    }

    final totalH = _headerH + _tiesInRound(0) * _baseSlotH;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: totalH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int level = 0; level < _numRounds; level++) ...[
                    if (level > 0)
                      _ConnectorColumn(
                        rightCount: _tiesInRound(level),
                        rightSlotH: _baseSlotH * (1 << level),
                        totalHeight: totalH,
                      ),
                    _RoundColumn(
                      label: _roundLabel(_tiesInRound(level)),
                      ties: rounds[level],
                      slotH: _baseSlotH * (1 << level),
                    ),
                  ],
                  _ConnectorColumn(
                    rightCount: 1,
                    rightSlotH: _baseSlotH * (1 << (_numRounds - 1)),
                    totalHeight: totalH,
                    straight: true,
                  ),
                  _ChampionColumn(
                    team: champion,
                    slotH: _baseSlotH * (1 << (_numRounds - 1)),
                  ),
                ],
              ),
            ),
          ),
          if (thirdPlace) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UTAKMICA ZA 3. MJESTO',
                    style: _labelStyle,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 2 * _colW,
                    child: thirdPlaceTie != null
                        ? _buildTieCard(thirdPlaceTie)
                        : const TieCard(
                            teamATbdLabel: 'Gubitnik PF1',
                            teamBTbdLabel: 'Gubitnik PF2',
                          ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

final TextStyle _labelStyle = TextStyle(
  fontFamily: AppFonts.roboto,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.primary,
  letterSpacing: 0.7,
);

TieCard _buildTieCard(PlayoffTie tie) {
  final w = tie.winner;
  final started = tie.status != 'scheduled';
  return TieCard(
    teamA: tie.teamA,
    teamB: tie.teamB,
    scoreA: started ? tie.aggregateA : null,
    scoreB: started ? tie.aggregateB : null,
    isWinnerA: w != null && tie.teamA?.clubId == w,
    isWinnerB: w != null && tie.teamB?.clubId == w,
  );
}

class _RoundColumn extends StatelessWidget {
  final String label;
  final List<PlayoffTie?> ties;
  final double slotH;

  const _RoundColumn({
    required this.label,
    required this.ties,
    required this.slotH,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _colW,
      child: Column(
        children: [
          SizedBox(
            height: _headerH,
            child: Center(child: Text(label, style: _labelStyle)),
          ),
          for (final tie in ties)
            SizedBox(
              height: slotH,
              child: Center(
                child: tie != null ? _buildTieCard(tie) : const TieCard(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChampionColumn extends StatelessWidget {
  final PlayoffTeam? team;
  final double slotH;

  const _ChampionColumn({required this.team, required this.slotH});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _colW,
      child: Column(
        children: [
          SizedBox(
            height: _headerH,
            child: Center(child: Text('PRVAK', style: _labelStyle)),
          ),
          SizedBox(
            height: slotH,
            child: Center(
              child: Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 26),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _colW - 70),
                        child: Text(
                          team?.clubName ?? 'Nije poznato',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 13,
                            fontWeight:
                                team != null ? FontWeight.w700 : FontWeight.w400,
                            color: team != null
                                ? AppColors.primary
                                : Colors.grey.shade500,
                            fontStyle: team != null
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical strip between two rounds drawing the classic bracket elbows:
/// each pair of slots on the left merges into one slot on the right.
class _ConnectorColumn extends StatelessWidget {
  final int rightCount;
  final double rightSlotH;
  final double totalHeight;
  final bool straight;

  const _ConnectorColumn({
    required this.rightCount,
    required this.rightSlotH,
    required this.totalHeight,
    this.straight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _connW,
      height: totalHeight,
      child: CustomPaint(
        painter: _ConnectorPainter(
          rightCount: rightCount,
          rightSlotH: rightSlotH,
          straight: straight,
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final int rightCount;
  final double rightSlotH;
  final bool straight;

  const _ConnectorPainter({
    required this.rightCount,
    required this.rightSlotH,
    this.straight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (straight) {
      final y = _headerH + rightSlotH / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      return;
    }

    final leftSlotH = rightSlotH / 2;
    for (int j = 0; j < rightCount; j++) {
      final topY = _headerH + (2 * j + 0.5) * leftSlotH;
      final botY = _headerH + (2 * j + 1.5) * leftSlotH;
      final midY = _headerH + (j + 0.5) * rightSlotH;
      final midX = size.width / 2;

      final path = Path()
        ..moveTo(0, topY)
        ..lineTo(midX, topY)
        ..lineTo(midX, botY)
        ..lineTo(0, botY)
        ..moveTo(midX, midY)
        ..lineTo(size.width, midY);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.rightCount != rightCount ||
      old.rightSlotH != rightSlotH ||
      old.straight != straight;
}
