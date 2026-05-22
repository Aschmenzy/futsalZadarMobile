import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/playoff_group_data.dart';

class PlayoffGroupStandingsTab extends StatelessWidget {
  final PlayoffGroupData data;

  const PlayoffGroupStandingsTab({super.key, required this.data});

  int get _safeZone => (data.standings.length / 2).ceil();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (data.autoPromoted.isNotEmpty) ...[
            _Banner(
              prefix: 'Automatski unaprijeđeni (L2 → L1)',
              clubs: data.autoPromoted.map((c) => c.clubName).join(', '),
              background: Colors.green.shade50,
              textColor: Colors.green.shade800,
            ),
            const SizedBox(height: 8),
          ],
          if (data.autoRelegated.isNotEmpty) ...[
            _Banner(
              prefix: 'Automatski ispali (L1 → L2)',
              clubs: data.autoRelegated.map((c) => c.clubName).join(', '),
              background: Colors.red.shade50,
              textColor: Colors.red.shade800,
            ),
            const SizedBox(height: 12),
          ],
          _StandingsCard(
            standings: data.standings,
            safeZone: _safeZone,
            label: data.label,
          ),
          const SizedBox(height: 12),
          _Legend(),
        ],
      ),
    );
  }
}

// ── Banners ────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final String prefix;
  final String clubs;
  final Color background;
  final Color textColor;

  const _Banner({
    required this.prefix,
    required this.clubs,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 12,
            color: textColor,
          ),
          children: [
            TextSpan(
              text: '$prefix: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: clubs),
          ],
        ),
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _StandingsCard extends StatelessWidget {
  final List<PlayoffGroupStanding> standings;
  final int safeZone;
  final String label;

  const _StandingsCard({
    required this.standings,
    required this.safeZone,
    required this.label,
  });

  static final _labelStyle = TextStyle(
    fontFamily: AppFonts.roboto,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: AppColors.primary,
  );

  static final _dataStyle = TextStyle(
    fontFamily: AppFonts.roboto,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    color: AppColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildColumnLabels(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          _buildRows(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildColumnLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: _labelStyle)),
          Expanded(child: Text('Tim', style: _labelStyle)),
          _labelCell('P'),
          _labelCell('W'),
          _labelCell('D'),
          _labelCell('L'),
          _labelCell('DIFF', width: 48),
          _labelCell('PTS', width: 40),
        ],
      ),
    );
  }

  Widget _labelCell(String text, {double width = 28}) {
    return SizedBox(
      width: width,
      child: Text(text, style: _labelStyle, textAlign: TextAlign.center),
    );
  }

  Widget _buildRows() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: standings.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF0F0F0),
        indent: 14,
        endIndent: 14,
      ),
      itemBuilder: (context, index) {
        final s = standings[index];
        final isPromoted = index < safeZone;
        return _buildRow(index + 1, s, isPromoted);
      },
    );
  }

  Widget _buildRow(int rank, PlayoffGroupStanding s, bool isPromoted) {
    final rowColor = isPromoted ? Colors.green.shade50 : Colors.red.shade50;
    final isUpper = s.league == 'upper';
    final diff = s.goalDiff;
    final diffText = diff > 0 ? '+$diff' : '$diff';

    return DecoratedBox(
      decoration: BoxDecoration(color: rowColor),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _clubLogo(s.clubLogo),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      s.clubName,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  _leagueBadge(isUpper),
                ],
              ),
            ),
            _dataCell('${s.played}'),
            _dataCell('${s.wins}'),
            _dataCell('${s.draws}'),
            _dataCell('${s.losses}'),
            _dataCell(diffText, width: 48),
            _dataCell('${s.points}', width: 40, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _clubLogo(String url) {
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _fallbackLogo(),
        ),
      );
    }
    return _fallbackLogo();
  }

  Widget _fallbackLogo() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _leagueBadge(bool isUpper) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isUpper ? Colors.blue.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isUpper ? 'L1' : 'L2',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isUpper ? Colors.blue.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _dataCell(String text, {double width = 28, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: bold
            ? _dataStyle.copyWith(fontWeight: FontWeight.w700)
            : _dataStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Legend ─────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item(Colors.green.shade100, 'Ostaje / napreduje'),
        const SizedBox(width: 16),
        _item(Colors.red.shade100, 'Pada / ostaje niže'),
      ],
    );
  }

  Widget _item(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
