import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/pages/matchDetailsPage/match_details_page.dart';
import 'package:futsalmobile/pages/playoffPage/widgets/tie_card.dart';
import 'package:futsalmobile/services/firebase_services.dart';

const double _pad = 12.0;
const double _connH = 32.0;

enum _ConnType { qfToSf, sfToFinal, finalToChampion }

class BracketWidget extends StatelessWidget {
  final List<PlayoffTie> ties;
  const BracketWidget({super.key, required this.ties});

  PlayoffTie? _tie(String id) {
    try {
      return ties.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onTieTap(BuildContext context, PlayoffTie tie) async {
    final legs = <String, String>{};
    if (tie.leg1MatchId != null) legs['Prva utakmica'] = tie.leg1MatchId!;
    if (!tie.isSingleLeg && tie.leg2MatchId != null) {
      legs['Uzvratna utakmica'] = tie.leg2MatchId!;
    }

    if (legs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utakmica još nije zakazana')),
      );
      return;
    }

    String? matchId;
    if (legs.length == 1) {
      matchId = legs.values.first;
    } else {
      matchId = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ...legs.entries.map(
                (e) => ListTile(
                  title: Text(
                    e.key,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  leading: const Icon(Icons.sports_soccer),
                  onTap: () => Navigator.pop(sheetCtx, e.value),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    if (matchId == null || !context.mounted) return;

    try {
      final match = await FirebaseService().getMatchDetail(matchId);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchDetailsPage(match: match)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Greška pri učitavanju utakmice')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qf1 = _tie('qf1');
    final qf2 = _tie('qf2');
    final sf1 = _tie('sf1');
    final sf2 = _tie('sf2');
    final finalTie = _tie('final');
    final thirdPlace = _tie('3rd_place');

    PlayoffTeam? champion;
    if (finalTie?.winner != null) {
      final id = finalTie!.winner!;
      champion = finalTie.teamA?.clubId == id ? finalTie.teamA : finalTie.teamB;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // slotW is exactly 1/4 of usable width so 4 QF cards fill the screen.
        final slotW = (constraints.maxWidth - _pad * 2) / 4;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: _pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── PRVAK ───────────────────────────────────────────────────
              _roundLabel('PRVAK', TextAlign.center),
              const SizedBox(height: 6),
              _ChampionRow(team: champion, slotW: slotW),

              _Connector(type: _ConnType.finalToChampion, slotW: slotW),

              // ── FINALE ──────────────────────────────────────────────────
              _roundLabel('FINALE', TextAlign.center),
              const SizedBox(height: 6),
              _FinalRow(
                tie: finalTie,
                slotW: slotW,
                onTap: finalTie != null
                    ? () => _onTieTap(context, finalTie)
                    : null,
              ),

              _Connector(type: _ConnType.sfToFinal, slotW: slotW),

              // ── POLUFINALE ──────────────────────────────────────────────
              _SfHeader(slotW: slotW),
              const SizedBox(height: 6),
              _SfRow(
                sf1: sf1,
                sf2: sf2,
                slotW: slotW,
                onTieTap: (tie) => _onTieTap(context, tie),
              ),

              _Connector(type: _ConnType.qfToSf, slotW: slotW),

              // ── ČETVRTFINALE ────────────────────────────────────────────
              _roundLabel('ČETVRTFINALE', TextAlign.center),
              const SizedBox(height: 6),
              _QfRow(
                qf1: qf1,
                qf2: qf2,
                sf1: sf1,
                sf2: sf2,
                slotW: slotW,
                onTieTap: (tie) => _onTieTap(context, tie),
              ),

              // ── 3. MJESTO ───────────────────────────────────────────────
              if (thirdPlace != null) ...[
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _roundLabel('UTAKMICA ZA 3. MJESTO', TextAlign.start),
                const SizedBox(height: 6),
                _GenericTie(
                  tie: thirdPlace,
                  tbdA: 'Gubitnik PF1',
                  tbdB: 'Gubitnik PF2',
                  onTap: () => _onTieTap(context, thirdPlace),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _roundLabel(String text, TextAlign align) => Text(
  text,
  textAlign: align,
  style: TextStyle(
    fontFamily: AppFonts.roboto,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0.7,
  ),
);

TieCard _buildTie(
  PlayoffTie? tie, {
  String tbdA = 'TBD',
  String tbdB = 'TBD',
  VoidCallback? onTap,
}) {
  if (tie == null) return TieCard(teamATbdLabel: tbdA, teamBTbdLabel: tbdB);
  final w = tie.winner;
  final s = tie.status != 'scheduled';
  return TieCard(
    teamA: tie.teamA,
    teamB: tie.teamB,
    teamATbdLabel: tbdA,
    teamBTbdLabel: tbdB,
    scoreA: s ? tie.aggregateA : null,
    scoreB: s ? tie.aggregateB : null,
    isWinnerA: w != null && tie.teamA?.clubId == w,
    isWinnerB: w != null && tie.teamB?.clubId == w,
    onTap: onTap,
  );
}

// ── SF header ─────────────────────────────────────────────────────────────────

class _SfHeader extends StatelessWidget {
  final double slotW;
  const _SfHeader({required this.slotW});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 2 * slotW,
          child: _roundLabel('POLUFINALE', TextAlign.center),
        ),
        SizedBox(
          width: 2 * slotW,
          child: _roundLabel('POLUFINALE', TextAlign.center),
        ),
      ],
    );
  }
}

// ── QF row ────────────────────────────────────────────────────────────────────

class _QfRow extends StatelessWidget {
  final PlayoffTie? qf1, qf2, sf1, sf2;
  final double slotW;
  final void Function(PlayoffTie)? onTieTap;
  const _QfRow({
    this.qf1,
    this.qf2,
    this.sf1,
    this.sf2,
    required this.slotW,
    this.onTieTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slot(
          TieCard(teamA: sf1?.teamA, teamATbdLabel: 'TBD', showByeBadge: true),
        ),
        _slot(
          _buildTie(
            qf1,
            onTap: qf1 != null ? () => onTieTap?.call(qf1!) : null,
          ),
        ),
        _slot(
          _buildTie(
            qf2,
            onTap: qf2 != null ? () => onTieTap?.call(qf2!) : null,
          ),
        ),
        _slot(
          TieCard(teamA: sf2?.teamA, teamATbdLabel: 'TBD', showByeBadge: true),
        ),
      ],
    );
  }

  Widget _slot(Widget child) => SizedBox(
    width: slotW,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: child,
    ),
  );
}

// ── SF row ────────────────────────────────────────────────────────────────────

class _SfRow extends StatelessWidget {
  final PlayoffTie? sf1, sf2;
  final double slotW;
  final void Function(PlayoffTie)? onTieTap;
  const _SfRow({this.sf1, this.sf2, required this.slotW, this.onTieTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 2 * slotW,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildTie(
              sf1,
              tbdA: 'Slobodan prolaz',
              tbdB: 'Pobjednik ČF',
              onTap: sf1 != null ? () => onTieTap?.call(sf1!) : null,
            ),
          ),
        ),
        SizedBox(
          width: 2 * slotW,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildTie(
              sf2,
              tbdA: 'Slobodan prolaz',
              tbdB: 'Pobjednik ČF',
              onTap: sf2 != null ? () => onTieTap?.call(sf2!) : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Final row ─────────────────────────────────────────────────────────────────

class _FinalRow extends StatelessWidget {
  final PlayoffTie? tie;
  final double slotW;
  final VoidCallback? onTap;
  const _FinalRow({this.tie, required this.slotW, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        // Cap at 2*slotW so it sits neatly in the middle two slots
        width: (2 * slotW).clamp(0.0, 280.0),
        child: _buildTie(
          tie,
          tbdA: 'Pobjednik PF1',
          tbdB: 'Pobjednik PF2',
          onTap: onTap,
        ),
      ),
    );
  }
}

// ── Champion row ──────────────────────────────────────────────────────────────

class _ChampionRow extends StatelessWidget {
  final PlayoffTeam? team;
  final double slotW;
  const _ChampionRow({this.team, required this.slotW});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: (2 * slotW).clamp(0.0, 220.0),
        child: Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team?.clubName ?? 'Nije poznato',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 13,
                      fontWeight: team != null
                          ? FontWeight.w700
                          : FontWeight.w400,
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
    );
  }
}

// ── Generic tie ───────────────────────────────────────────────────────────────

class _GenericTie extends StatelessWidget {
  final PlayoffTie? tie;
  final String tbdA, tbdB;
  final VoidCallback? onTap;
  const _GenericTie({
    this.tie,
    required this.tbdA,
    required this.tbdB,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      _buildTie(tie, tbdA: tbdA, tbdB: tbdB, onTap: onTap);
}

// ── Connector ─────────────────────────────────────────────────────────────────

class _Connector extends StatelessWidget {
  final _ConnType type;
  final double slotW;
  const _Connector({required this.type, required this.slotW});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4 * slotW,
      height: _connH,
      child: CustomPaint(
        painter: _ConnPainter(type: type, slotW: slotW),
      ),
    );
  }
}

class _ConnPainter extends CustomPainter {
  final _ConnType type;
  final double slotW;
  const _ConnPainter({required this.type, required this.slotW});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mid = size.height / 2;

    // Slot-center x positions derived from slotW
    final qfC0 = slotW * 0.5;
    final qfC1 = slotW * 1.5;
    final qfC2 = slotW * 2.5;
    final qfC3 = slotW * 3.5;
    final sfC0 = slotW * 1.0;
    final sfC1 = slotW * 3.0;
    final finC = slotW * 2.0;

    switch (type) {
      case _ConnType.qfToSf:
        // Left branch: SF1 (sfC0) → Bye (qfC0) + QF1 (qfC1)
        _v(canvas, p, sfC0, 0, mid);
        _h(canvas, p, qfC0, qfC1, mid);
        _v(canvas, p, qfC0, mid, size.height);
        _v(canvas, p, qfC1, mid, size.height);
        // Right branch: SF2 (sfC1) → QF2 (qfC2) + Bye (qfC3)
        _v(canvas, p, sfC1, 0, mid);
        _h(canvas, p, qfC2, qfC3, mid);
        _v(canvas, p, qfC2, mid, size.height);
        _v(canvas, p, qfC3, mid, size.height);

      case _ConnType.sfToFinal:
        // Final (finC) → SF1 (sfC0) + SF2 (sfC1)
        _v(canvas, p, finC, 0, mid);
        _h(canvas, p, sfC0, sfC1, mid);
        _v(canvas, p, sfC0, mid, size.height);
        _v(canvas, p, sfC1, mid, size.height);

      case _ConnType.finalToChampion:
        _v(canvas, p, finC, 0, size.height);
    }
  }

  void _h(Canvas c, Paint p, double x1, double x2, double y) =>
      c.drawLine(Offset(x1, y), Offset(x2, y), p);
  void _v(Canvas c, Paint p, double x, double y1, double y2) =>
      c.drawLine(Offset(x, y1), Offset(x, y2), p);

  @override
  bool shouldRepaint(_ConnPainter old) =>
      old.type != type || old.slotW != slotW;
}
