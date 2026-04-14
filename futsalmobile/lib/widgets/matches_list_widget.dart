import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/favorite_item.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/services/favorites_service.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/match_row_widget.dart';

class MatchesListWidget extends StatefulWidget {
  final String leagueId;
  final String season;
  final String? clubFilter;
  final Widget? Function(MatchData match)? trailingBuilder;

  const MatchesListWidget({
    super.key,
    required this.leagueId,
    required this.season,
    this.clubFilter,
    this.trailingBuilder,
  });

  @override
  State<MatchesListWidget> createState() => _MatchesListWidgetState();
}

class _MatchesListWidgetState extends State<MatchesListWidget> {
  final _service = FirebaseService();

  List<MatchData> _matches = [];
  Map<int, List<MatchData>> _matchesByRound = {};
  bool _loading = true;
  String? _error;

  int? _selectedRound;
  String? _selectedClub;
  List<String> _allClubs = [];
  List<int> _allRounds = [];

  StreamSubscription? _invalidationSub;
  // Set to true whenever cache is invalidated — next _loadData() bypasses Hive
  bool _forceRefresh = false;

  @override
  void initState() {
    super.initState();
    // If the cache was invalidated while this widget wasn't mounted yet,
    // the broadcast event was lost — check the dirty flag to catch it.
    _forceRefresh = _service.consumeMatchCacheDirty();
    _loadData();
    // Re-fetch whenever the admin bumps lastUpdated while the app is open.
    _invalidationSub = _service.onCacheInvalidated.listen((_) {
      _forceRefresh = true;
      _loadData();
    });
  }

  @override
  void dispose() {
    _invalidationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final forceRefresh = _forceRefresh;
    _forceRefresh = false;
    try {
      final allMatches = await _service.getAllMatches(
        widget.leagueId,
        season: widget.season,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      // Pre-filter by club when clubFilter is set
      final matches = widget.clubFilter != null
          ? allMatches
                .where(
                  (m) =>
                      m.homeTeam == widget.clubFilter ||
                      m.awayTeam == widget.clubFilter,
                )
                .toList()
          : allMatches;

      final Map<int, List<MatchData>> grouped = {};
      final Set<String> clubs = {};
      final Set<int> rounds = {};

      for (final match in matches) {
        grouped.putIfAbsent(match.round, () => []).add(match);
        clubs.add(match.homeTeam);
        clubs.add(match.awayTeam);
        rounds.add(match.round);
      }

      setState(() {
        _matches = matches;
        _matchesByRound = grouped;
        _allClubs = clubs.toList()..sort();
        _allRounds = rounds.toList()..sort((a, b) => b.compareTo(a));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greska pri ucitavanju: $e';
        _loading = false;
      });
    }
  }

  Map<int, List<MatchData>> get _filtered {
    Map<int, List<MatchData>> source = _matchesByRound;

    if (_selectedClub != null) {
      source = {};
      for (final entry in _matchesByRound.entries) {
        final f = entry.value
            .where(
              (m) => m.homeTeam == _selectedClub || m.awayTeam == _selectedClub,
            )
            .toList();
        if (f.isNotEmpty) source[entry.key] = f;
      }
    }

    if (_selectedRound != null) {
      return {
        if (source.containsKey(_selectedRound!))
          _selectedRound!: source[_selectedRound!]!,
      };
    }

    return source;
  }

  bool get _hasActiveFilter => _selectedRound != null || _selectedClub != null;
  bool get _showClubChip => widget.clubFilter == null;

  String? _result(MatchData match) {
    if (!match.isFinished) return null;
    final int clubGoals;
    final int opponentGoals;
    final String? club = widget.clubFilter;
    if (club != null && match.awayTeam == club) {
      clubGoals = match.awayTeamGoals;
      opponentGoals = match.homeTeamGoals;
    } else {
      clubGoals = match.homeTeamGoals;
      opponentGoals = match.awayTeamGoals;
    }
    if (clubGoals > opponentGoals) return 'W';
    if (clubGoals == opponentGoals) return 'D';
    return 'L';
  }

  Color _resultColor(String result) {
    switch (result) {
      case 'W':
        return AppColors.gameWon;
      case 'D':
        return AppColors.gameDraw;
      case 'L':
        return AppColors.liveGame;
      default:
        return Colors.grey;
    }
  }

  Widget _trailing(MatchData match) {
    final result = _result(match);
    if (result != null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _resultColor(result),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          result,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      );
    }
    // Scheduled match — show live, tappable notification bell
    return _MatchNotificationBell(match: match);
  }

  void _showRoundPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filtriraj po kolu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: AppFonts.roboto,
              ),
            ),
          ),
          ListTile(
            title: Text(
              'Sva kola',
              style: TextStyle(fontFamily: AppFonts.roboto),
            ),
            trailing: _selectedRound == null
                ? const Icon(Icons.check, color: AppColors.secondary)
                : null,
            onTap: () {
              setState(() => _selectedRound = null);
              Navigator.pop(context);
            },
          ),
          ..._allRounds.map(
            (r) => ListTile(
              title: Text(
                '$r. kolo',
                style: TextStyle(fontFamily: AppFonts.roboto),
              ),
              trailing: _selectedRound == r
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
              onTap: () {
                setState(() => _selectedRound = r);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClubPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filtriraj po klubu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: AppFonts.roboto,
              ),
            ),
          ),
          ListTile(
            title: Text(
              'Svi klubovi',
              style: TextStyle(fontFamily: AppFonts.roboto),
            ),
            trailing: _selectedClub == null
                ? const Icon(Icons.check, color: AppColors.secondary)
                : null,
            onTap: () {
              setState(() => _selectedClub = null);
              Navigator.pop(context);
            },
          ),
          ..._allClubs.map(
            (c) => ListTile(
              title: Text(c),
              trailing: _selectedClub == c
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
              onTap: () {
                setState(() => _selectedClub = c);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = _filtered.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: [
        if (!_loading && _error == null && _matches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                _filterChip(
                  label: _selectedRound != null
                      ? '$_selectedRound. kolo'
                      : 'Kolo',
                  active: _selectedRound != null,
                  onTap: _showRoundPicker,
                ),
                if (_showClubChip) ...[
                  const SizedBox(width: 8),
                  _filterChip(
                    label: _selectedClub ?? 'Klub',
                    active: _selectedClub != null,
                    onTap: _showClubPicker,
                  ),
                ],
                if (_hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedRound = null;
                      _selectedClub = null;
                    }),
                    child: const Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),

        Expanded(
          child: ColoredBox(
            color: AppColors.background,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _matches.isEmpty
                ? Center(
                    child: Text(
                      'Nema utakmica',
                      style: TextStyle(fontFamily: AppFonts.roboto),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: sortedEntries.fold<int>(
                      0,
                      (sum, e) => sum + 1 + e.value.length,
                    ),
                    itemBuilder: (context, index) {
                      int cursor = 0;
                      for (final entry in sortedEntries) {
                        if (index == cursor) {
                          return _roundHeader(entry.key);
                        }
                        cursor++;
                        final matchIndex = index - cursor;
                        if (matchIndex < entry.value.length) {
                          final match = entry.value[matchIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: MatchRowWidget(
                              match: match,
                              trailing: _trailing(match),
                            ),
                          );
                        }
                        cursor += entry.value.length;
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.ternary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.secondary : AppColors.ternaryGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.ternaryGray,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: active ? Colors.white : AppColors.ternaryGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundHeader(int round) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.ternaryGray)),
          const SizedBox(width: 8),
          Text(
            '$round. kolo',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ternaryGray,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: AppColors.ternaryGray)),
        ],
      ),
    );
  }
}

/// Live, tappable notification bell for a single scheduled match.
/// Uses StreamBuilder so the icon updates instantly across the app.
class _MatchNotificationBell extends StatelessWidget {
  final MatchData match;
  const _MatchNotificationBell({required this.match});

  @override
  Widget build(BuildContext context) {
    final favService = FavoritesService();
    return StreamBuilder<FavoriteItem?>(
      stream: favService.watchEntity(match.matchId),
      builder: (context, snap) {
        final isNotif = snap.data?.notificationsEnabled ?? false;
        return GestureDetector(
          onTap: () => favService.toggleNotification(
            FavoriteItem(
              entityId: match.matchId,
              type: 'match',
              name: '${match.homeTeam} vs ${match.awayTeam}',
              imageUrl: '',
              leagueId: match.leagueCode,
              leagueName: match.leagueCode,
              starred: snap.data?.starred ?? false,
              notificationsEnabled: isNotif,
              createdAt: DateTime.now(),
            ),
          ),
          child: Icon(
            isNotif ? Icons.notifications : Icons.notifications_none,
            color: isNotif ? AppColors.accentYellow : Colors.grey.shade400,
            size: 28,
          ),
        );
      },
    );
  }
}
