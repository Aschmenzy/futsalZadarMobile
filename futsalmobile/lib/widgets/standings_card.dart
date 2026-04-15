import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/clubStanding.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/pages/clubDetailsPage/club_cetails_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';

enum StandingsView { detailed, simple, form }

class StandingsCard extends StatefulWidget {
  final String leagueCode;
  final String leagueName;
  final String leaugeSeason;
  final String? highlightedClubId;

  const StandingsCard({
    super.key,
    required this.leagueCode,
    required this.leagueName,
    required this.leaugeSeason,
    this.highlightedClubId,
  });

  @override
  State<StandingsCard> createState() => _StandingsCardState();
}

class _StandingsCardState extends State<StandingsCard> {
  final _service = FirebaseService();
  List<ClubStanding> _standings = [];
  // clubName → last 5 results (newest first), e.g. ['W','L','D']
  Map<String, List<String>> _form = {};
  bool _loading = true;
  String? _error;
  StandingsView _view = StandingsView.detailed;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getAllClubsInLeague(
          widget.leagueCode,
          season: widget.leaugeSeason,
        ),
        _service.getAllMatches(widget.leagueCode, season: widget.leaugeSeason),
      ]);
      if (!mounted) return;

      final standings = results[0] as List<ClubStanding>;
      final matches = results[1] as List<MatchData>;

      // Keep only finished/awarded matches, newest first (already ordered by Firestore)
      final finished = matches
          .where((m) => m.isFinished || m.isAwarded)
          .toList();

      final form = <String, List<String>>{};
      for (final club in standings) {
        final clubMatches = finished
            .where(
              (m) => m.homeTeam == club.clubName || m.awayTeam == club.clubName,
            )
            .take(5)
            .toList();

        form[club.clubName] = clubMatches.map((m) {
          final isHome = m.homeTeam == club.clubName;
          final scored = isHome ? m.homeTeamGoals : m.awayTeamGoals;
          final conceded = isHome ? m.awayTeamGoals : m.homeTeamGoals;
          if (scored > conceded) return 'W';
          if (scored < conceded) return 'L';
          return 'D';
        }).toList();
      }

      setState(() {
        _standings = standings;
        _form = form;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greška pri učitavanju: $e';
        _loading = false;
      });
    }
  }

  void _onClubTap(ClubStanding club) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubCetailsPage(
          leagueId: widget.leagueCode,
          clubId: club.clubId,
          clubName: club.clubName,
          clubLogo: club.clubLogo,
          leagueName: widget.leagueName,
          season: widget.leaugeSeason,
        ),
      ),
    );
  }

  void _showViewMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<StandingsView>(
      context: context,
      position: position,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        _menuItem(
          value: StandingsView.detailed,
          label: 'Detaljan prikaz',
          subtitle: '# Tim  P  W  D  L  DIFF  PTS',
          isSelected: _view == StandingsView.detailed,
        ),
        _menuItem(
          value: StandingsView.simple,
          label: 'Jednostavan prikaz',
          subtitle: '# Tim  P  DIFF  PTS',
          isSelected: _view == StandingsView.simple,
        ),
        _menuItem(
          value: StandingsView.form,
          label: 'Zadnje utakmice',
          subtitle: '# Tim  Zadnje',
          isSelected: _view == StandingsView.form,
        ),
      ],
    );

    if (selected != null && selected != _view) {
      setState(() => _view = selected);
    }
  }

  PopupMenuItem<StandingsView> _menuItem({
    required StandingsView value,
    required String label,
    required String subtitle,
    required bool isSelected,
  }) {
    return PopupMenuItem<StandingsView>(
      value: value,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? AppColors.secondary : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.ternaryGray,
                    fontFamily: AppFonts.roboto,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check, size: 16, color: AppColors.secondary),
        ],
      ),
    );
  }

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
          _buildBody(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.leagueName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => _showViewMenu(ctx),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Column labels ─────────────────────────────────────────────────────────────

  Widget _buildColumnLabels() {
    dynamic labelStyle = TextStyle(
      fontFamily: AppFonts.roboto,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: AppColors.primary,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (_view) {
        StandingsView.detailed => _detailedLabels(labelStyle),
        StandingsView.simple => _simpleLabels(labelStyle),
        StandingsView.form => _formLabels(labelStyle),
      },
    );
  }

  Widget _detailedLabels(TextStyle style) {
    return Padding(
      key: const ValueKey('detailed-labels'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: style)),
          Expanded(child: Text('Tim', style: style)),
          _labelCell('P', style),
          _labelCell('W', style),
          _labelCell('D', style),
          _labelCell('L', style),
          _labelCell('DIFF', style, width: 48),
          _labelCell('PTS', style, width: 40),
        ],
      ),
    );
  }

  Widget _simpleLabels(TextStyle style) {
    return Padding(
      key: const ValueKey('simple-labels'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: style)),
          Expanded(child: Text('Tim', style: style)),
          _labelCell('P', style, width: 40),
          _labelCell('DIFF', style, width: 52),
          _labelCell('PTS', style, width: 40),
        ],
      ),
    );
  }

  Widget _labelCell(String text, TextStyle style, {double width = 28}) {
    return SizedBox(
      width: width,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );
    }

    const int minRows = 2;
    final int rowCount = _standings.length > minRows
        ? _standings.length
        : minRows;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: ListView.separated(
        key: ValueKey(_view),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rowCount,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFF0F0F0),
          indent: 14,
          endIndent: 14,
        ),
        itemBuilder: (context, index) {
          final hasData = index < _standings.length;
          final club = hasData ? _standings[index] : null;
          return switch (_view) {
            StandingsView.detailed => _buildDetailedRow(index + 1, club),
            StandingsView.simple => _buildSimpleRow(index + 1, club),
            StandingsView.form => _buildFormRow(index + 1, club),
          };
        },
      ),
    );
  }

  // ── Detailed row ──────────────────────────────────────────────────────────────

  Widget _buildDetailedRow(int rank, ClubStanding? club) {
    dynamic dataStyle = TextStyle(
      fontFamily: AppFonts.roboto,
      fontWeight: FontWeight.w500,
      fontSize: 13,
      color: AppColors.primary,
    );

    final isHighlighted =
        club != null &&
        widget.highlightedClubId != null &&
        club.clubId == widget.highlightedClubId;

    return GestureDetector(
      onTap: club == null ? null : () => _onClubTap(club),
      child: DecoratedBox(
        decoration: isHighlighted
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.secondary, width: 3),
                ),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: EdgeInsets.only(
            left: isHighlighted ? 11 : 14,
            right: 14,
            top: 10,
            bottom: 10,
          ),
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
                    _clubLogo(club),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        club?.clubName ?? '',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _dataCell('${club?.matchesPlayed ?? ''}', dataStyle),
              _dataCell('${club?.wins ?? ''}', dataStyle),
              _dataCell('${club?.draws ?? ''}', dataStyle),
              _dataCell('${club?.losses ?? ''}', dataStyle),
              _dataCell(_diffText(club?.goalDifference), dataStyle, width: 48),
              _dataCell(
                '${club?.points ?? ''}',
                dataStyle.copyWith(fontWeight: FontWeight.w700),
                width: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Simple row ────────────────────────────────────────────────────────────────

  Widget _buildSimpleRow(int rank, ClubStanding? club) {
    dynamic dataStyle = TextStyle(
      fontFamily: AppFonts.roboto,
      fontWeight: FontWeight.w500,
      fontSize: 13,
      color: AppColors.primary,
    );

    final isHighlighted =
        club != null &&
        widget.highlightedClubId != null &&
        club.clubId == widget.highlightedClubId;

    return GestureDetector(
      onTap: club == null ? null : () => _onClubTap(club),
      child: DecoratedBox(
        decoration: isHighlighted
            ? const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.secondary, width: 3),
                ),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: EdgeInsets.only(
            left: isHighlighted ? 11 : 14,
            right: 14,
            top: 10,
            bottom: 10,
          ),
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
                    _clubLogo(club),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        club?.clubName ?? '',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _dataCell('${club?.matchesPlayed ?? ''}', dataStyle, width: 40),
              _dataCell(_diffText(club?.goalDifference), dataStyle, width: 52),
              _dataCell(
                '${club?.points ?? ''}',
                dataStyle.copyWith(fontWeight: FontWeight.w700),
                width: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form labels ───────────────────────────────────────────────────────────────

  Widget _formLabels(TextStyle style) {
    return Padding(
      key: const ValueKey('form-labels'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: style)),
          Expanded(child: Text('Tim', style: style)),
          Text('Zadnje', style: style),
        ],
      ),
    );
  }

  // ── Form row ──────────────────────────────────────────────────────────────────

  Widget _buildFormRow(int rank, ClubStanding? club) {
    final isHighlighted =
        club != null &&
        widget.highlightedClubId != null &&
        club.clubId == widget.highlightedClubId;

    final results = club != null ? (_form[club.clubName] ?? []) : <String>[];

    return GestureDetector(
      onTap: club == null ? null : () => _onClubTap(club),
      child: DecoratedBox(
        decoration: isHighlighted
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.secondary, width: 3),
                ),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: EdgeInsets.only(
            left: isHighlighted ? 11 : 14,
            right: 14,
            top: 10,
            bottom: 10,
          ),
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
                    _clubLogo(club),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        club?.clubName ?? '',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final r in results) _formBadge(r),
                  // fill remaining slots so layout is consistent
                  for (int i = results.length; i < 5; i++) _formBadge(null),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formBadge(String? result) {
    Color bg;
    switch (result) {
      case 'W':
        bg = AppColors.gameWon;
      case 'D':
        bg = AppColors.gameDraw;
      case 'L':
        bg = AppColors.gameLost;
      default:
        bg = AppColors.ternaryGray;
    }

    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(left: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: result != null
          ? Text(
              result,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _diffText(int? diff) {
    if (diff == null) return '';
    return diff > 0 ? '+$diff' : '$diff';
  }

  Widget _clubLogo(ClubStanding? club) {
    if (club == null) return const SizedBox(width: 22);
    if (club.clubLogo.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          club.clubLogo,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackLogo(),
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

  Widget _dataCell(String text, TextStyle style, {double width = 28}) {
    return SizedBox(
      width: width,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
}
