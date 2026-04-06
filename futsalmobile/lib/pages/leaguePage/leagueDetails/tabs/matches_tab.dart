import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/league_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class MatchesTab extends StatefulWidget {
  final LeagueData league;
  final String season;
  const MatchesTab({super.key, required this.league, required this.season});

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  final _service = FirebaseService();
  List<MatchData> _matches = [];
  Map<int, List<MatchData>> _matchesByRound = {};
  MatchData? _nextMatch;
  bool _loading = true;
  String? _error;

  // Filter state
  int? _selectedRound;
  String? _selectedClub;
  List<String> _allClubs = [];
  List<int> _allRounds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getAllMatches(widget.league.id, season: widget.season),
      ]);

      if (!mounted) return;

      final matches = results[0];

      // Build round map
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

  // Returns filtered map based on active filters
  Map<int, List<MatchData>> get _filteredByRound {
    Map<int, List<MatchData>> source = _matchesByRound;

    // Filter by club first
    if (_selectedClub != null) {
      source = {};
      for (final entry in _matchesByRound.entries) {
        final filtered = entry.value
            .where(
              (m) => m.homeTeam == _selectedClub || m.awayTeam == _selectedClub,
            )
            .toList();
        if (filtered.isNotEmpty) source[entry.key] = filtered;
      }
    }

    // Filter by round
    if (_selectedRound != null) {
      return {
        if (source.containsKey(_selectedRound!))
          _selectedRound!: source[_selectedRound!]!,
      };
    }

    return source;
  }

  String _formatDate(String matchDate) {
    final parts = matchDate.split('-');
    if (parts.length != 3) return matchDate;
    return '${parts[2]}/${parts[1]}/${parts[0].substring(2)}';
  }

  String _formatTime(String matchDate, String matchTime) {
    final date = DateTime.tryParse(matchDate);
    if (date == null) return matchTime;
    final now = DateTime.now();
    final matchDateTime = DateTime.tryParse('$matchDate $matchTime') ?? date;
    return matchDateTime.isBefore(now) ? 'FT' : matchTime;
  }

  void _showRoundFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filtriraj po kolu',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ListTile(
            title: const Text('Sva kola'),
            trailing: _selectedRound == null
                ? const Icon(Icons.check, color: AppColors.secondary)
                : null,
            onTap: () {
              setState(() => _selectedRound = null);
              Navigator.pop(context);
            },
          ),
          ..._allRounds.map(
            (round) => ListTile(
              title: Text('$round. kolo'),
              trailing: _selectedRound == round
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
              onTap: () {
                setState(() => _selectedRound = round);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClubFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filtriraj po klubu',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ListTile(
            title: const Text('Svi klubovi'),
            trailing: _selectedClub == null
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              setState(() => _selectedClub = null);
              Navigator.pop(context);
            },
          ),
          ..._allClubs.map(
            (club) => ListTile(
              title: Text(club),
              trailing: _selectedClub == club
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _selectedClub = club);
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
    final filtered = _filteredByRound;
    final sortedEntries = filtered.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: [
        // ── Filter bar ──
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
                  onTap: _showRoundFilter,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _selectedClub ?? 'Klub',
                  active: _selectedClub != null,
                  onTap: _showClubFilter,
                ),
                if (_selectedRound != null || _selectedClub != null) ...[
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

        // ── List ──
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
                ? const Center(child: Text('Nema utakmica'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    // Count: one header + N matches per round
                    itemCount: sortedEntries.fold<int>(
                      0,
                      (sum, e) => sum + 1 + e.value.length,
                    ),
                    itemBuilder: (context, index) {
                      // Map flat index → round header or match row
                      int cursor = 0;
                      for (final entry in sortedEntries) {
                        if (index == cursor) {
                          // Round header
                          return _roundHeader(entry.key);
                        }
                        cursor++;
                        final matchIndex = index - cursor;
                        if (matchIndex < entry.value.length) {
                          final match = entry.value[matchIndex];
                          final isNext =
                              _nextMatch != null &&
                              match.matchId == _nextMatch!.matchId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _matchRow(
                              _formatDate(match.matchDate),
                              _formatTime(match.matchDate, match.matchTime),
                              match.homeTeam,
                              match.awayTeam,
                              match.homeTeamLogo,
                              match.awayTeamLogo,
                              match.homeTeamGoals.toString(),
                              match.awayTeamGoals.toString(),
                              isNext: isNext,
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
          color: active ? Colors.blue : AppColors.ternary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.blue : AppColors.ternaryGray,
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

  Widget _matchRow(
    String date,
    String time,
    String home,
    String away,
    String homeLogo,
    String awayLogo,
    String hScore,
    String aScore, {
    bool isNext = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 13,
                    color: AppColors.ternaryGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 13,
                    color: AppColors.ternaryGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 2.5,
            color: AppColors.ternaryGray,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _teamRow(homeLogo, home, isNetwork: true),
                const SizedBox(height: 5),
                _teamRow(awayLogo, away, isNetwork: true),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hScore,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                aScore,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          VerticalDivider(
            width: 1,
            thickness: 2.5,
            color: AppColors.ternaryGray,
          ),
          const SizedBox(width: 8),
          Icon(
            isNext ? Icons.notifications_active : Icons.notifications_none,
            color: isNext ? Colors.amber : Colors.grey.shade400,
            size: 35,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _teamRow(String logo, String name, {bool isNetwork = false}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: isNetwork
                ? Image.network(
                    logo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.sports, size: 16),
                  )
                : Image.asset(logo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ),
      ],
    );
  }
}
