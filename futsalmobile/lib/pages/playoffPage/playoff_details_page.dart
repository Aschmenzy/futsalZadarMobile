import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_appBar.dart';
import 'package:futsalmobile/pages/playoffPage/tabs/bracket_tab.dart';
import 'package:futsalmobile/pages/playoffPage/tabs/playoff_matches_tab.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class PlayoffDetailsPage extends StatefulWidget {
  final String playoffId;
  final String displayName;
  // isGroup: true for ligaska group playoffs (direct match documents),
  // false for liga1 knockout bracket (tie structure)
  final bool isGroup;

  const PlayoffDetailsPage({
    super.key,
    required this.playoffId,
    required this.displayName,
    this.isGroup = false,
  });

  @override
  State<PlayoffDetailsPage> createState() => _PlayoffDetailsPageState();
}

class _PlayoffDetailsPageState extends State<PlayoffDetailsPage>
    with SingleTickerProviderStateMixin {
  final _service = FirebaseService();

  late TabController _tabController;

  List<PlayoffTie> _ties = [];
  List<MatchData> _groupMatches = [];
  String _season = '';
  bool _loading = true;
  String? _error;
  StreamSubscription? _invalidationSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isGroup ? 1 : 2,
      vsync: this,
    );
    _load();
    _invalidationSub = _service.onCacheInvalidated.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _invalidationSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final season = await _service.getActiveSeason();
      if (widget.isGroup) {
        final matches = await _service.getPlayoffGroupMatches(
          widget.playoffId,
          season: season,
        );
        if (!mounted) return;
        setState(() {
          _groupMatches = matches;
          _season = season;
          _loading = false;
        });
      } else {
        final ties = await _service.getPlayoffTies(widget.playoffId);
        if (!mounted) return;
        setState(() {
          _ties = ties;
          _season = season;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greška pri učitavanju: $e';
        _loading = false;
      });
    }
  }

  List<String> get _allMatchIds =>
      _ties.expand((tie) => tie.allMatchIds).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: LeagueAppBar(
        leagueName: widget.displayName,
        season: _season.isEmpty ? '...' : _season,
        seasons: const [],
        tabController: _tabController,
        showSeasonPicker: false,
        tabs: widget.isGroup
            ? const [Tab(text: 'Utakmice')]
            : const [Tab(text: 'Nosač'), Tab(text: 'Utakmice')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: widget.isGroup
                      ? [PlayoffMatchesTab(matches: _groupMatches)]
                      : [
                          BracketTab(ties: _ties),
                          PlayoffMatchesTab(matchIds: _allMatchIds),
                        ],
                ),
    );
  }
}
