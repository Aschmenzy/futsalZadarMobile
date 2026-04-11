import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/search_entry.dart';
import 'package:futsalmobile/pages/clubDetailsPage/club_cetails_page.dart';
import 'package:futsalmobile/pages/playerDetailsPage/player_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/services/search_service.dart';

/// Search bar that queries the local SearchService index (zero Firestore reads
/// per keystroke). Shows an overlay dropdown with club / player results.
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
  List<SearchEntry> _results = [];
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
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
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onChanged(String query) {
    final results = _search.search(query);
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
    // Capture width now (RenderBox is resolved at interaction time, not build time)
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

  Future<void> _onResultTap(SearchEntry entry) async {
    if (_navigating) return;
    _navigating = true;
    _clearSearch();

    final season = await _firebase.getActiveSeason();

    if (!mounted) {
      _navigating = false;
      return;
    }

    if (entry.type == 'club') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubCetailsPage(
            clubId: entry.id,
            clubName: entry.displayName,
            leagueId: entry.leagueId,
            clubLogo: entry.imageUrl ?? '',
            leagueName: entry.leagueName,
            season: season,
          ),
        ),
      );
    } else {
      // Player — fetch ClubData and PlayerData from cache (fast Hive reads)
      final clubs = await _firebase.getClubsByLeague(entry.leagueId);
      ClubData? clubData;
      try {
        clubData = clubs.firstWhere((c) => c.id == entry.clubId);
      } catch (_) {}

      if (!mounted) {
        _navigating = false;
        return;
      }

      if (clubData == null) {
        _navigating = false;
        return;
      }

      final players =
          await _firebase.getPlayersByClub(entry.leagueId, entry.clubId!);
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
            leagueId: entry.leagueId,
            clubData: clubData!,
            leaugeName: entry.leagueName,
          ),
        ),
      );
    }

    _navigating = false;
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
                  hintText: 'Pretraži igrače, klubove...',
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
                  child: Icon(Icons.close, size: 18, color: AppColors.ternaryGray),
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
  final SearchEntry entry;
  final VoidCallback onTap;

  const _ResultTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPlayer = entry.type == 'player';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                    ? Image.network(
                        entry.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackIcon(isPlayer),
                      )
                    : _fallbackIcon(isPlayer),
              ),
            ),

            const SizedBox(width: 10),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.displayName,
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
                    entry.subtitle,
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

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPlayer
                    ? AppColors.secondary.withAlpha(20)
                    : AppColors.accentYellow.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPlayer ? 'Igrač' : 'Klub',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isPlayer ? AppColors.secondary : const Color(0xFF9B7800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(bool isPlayer) {
    return Icon(
      isPlayer ? Icons.person : Icons.sports_soccer,
      size: 20,
      color: AppColors.ternaryGray,
    );
  }
}
