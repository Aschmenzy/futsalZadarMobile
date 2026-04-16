import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/pages/playerDetailsPage/player_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/services/search_service.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({super.key});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _search = SearchService();
  final _firebase = FirebaseService();
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<PlayerSearchResult> _results = [];
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _search.ensureIndexLoaded();
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _removeOverlay();
  }

  Future<void> _onChanged(String query) async {
    final results = await _search.search(query);
    if (!mounted) return;
    setState(() => _results = results);

    if (query.trim().isEmpty) {
      _removeOverlay();
      return;
    }

    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300.0;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay(width));
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _results = []);
    _removeOverlay();
    _focusNode.unfocus();
  }

  Future<void> _onResultTap(PlayerSearchResult entry) async {
    if (_navigating) return;
    _navigating = true;
    _clearSearch();

    if (!mounted) {
      _navigating = false;
      return;
    }

    final clubs = await _firebase.getClubsByLeague(entry.league);
    ClubData? clubData;
    try {
      clubData = clubs.firstWhere((c) => c.id == entry.clubId);
    } catch (_) {}

    if (!mounted || clubData == null) {
      _navigating = false;
      return;
    }

    final players = await _firebase.getPlayersByClub(
      entry.league,
      entry.clubId,
    );
    final player = players.where((p) => p.id == entry.id).firstOrNull;

    if (!mounted || player == null) {
      _navigating = false;
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerDetailsPage(
          player: player,
          leagueId: entry.league,
          clubData: clubData!,
          leaugeName: _leagueName(entry.league),
        ),
      ),
    );

    _navigating = false;
  }

  String _leagueName(String leagueId) {
    const names = {
      'liga1': 'Liga 1',
      'liga2': 'Liga 2',
      'liga3': 'Liga 3',
      'liga4': 'Liga 4',
    };
    return names[leagueId] ?? leagueId;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, size: 20, color: AppColors.ternaryGray),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: 'Pretraži igrače...',
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14,
                    color: AppColors.ternaryGray,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.ternaryGray,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(double width) {
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 48),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E4E4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nema rezultata',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 13,
                        color: AppColors.ternaryGray,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                      indent: 52,
                    ),
                    itemBuilder: (_, i) => _ResultTile(
                      entry: _results[i],
                      onTap: () => _onResultTap(_results[i]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final PlayerSearchResult entry;
  final VoidCallback onTap;

  const _ResultTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                    ? Image.network(
                        entry.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackIcon(),
                      )
                    : _fallbackIcon(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.fullName,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.clubName,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 11,
                      color: AppColors.ternaryGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Igrač',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Icon(Icons.person, size: 20, color: AppColors.ternaryGray);
  }
}
