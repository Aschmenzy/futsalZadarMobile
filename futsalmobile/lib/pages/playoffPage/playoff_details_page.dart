import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_appBar.dart';
import 'package:futsalmobile/pages/playoffPage/tabs/bracket_tab.dart';
import 'package:futsalmobile/pages/playoffPage/tabs/playoff_matches_tab.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class PlayoffDetailsPage extends StatefulWidget {
  final String playoffId;
  final String displayName;

  const PlayoffDetailsPage({
    super.key,
    required this.playoffId,
    required this.displayName,
  });

  @override
  State<PlayoffDetailsPage> createState() => _PlayoffDetailsPageState();
}

class _PlayoffDetailsPageState extends State<PlayoffDetailsPage>
    with SingleTickerProviderStateMixin {
  final _service = FirebaseService();

  late TabController _tabController;

  List<PlayoffTie> _ties = [];
  String _season = '';
  bool _loading = true;
  String? _error;
  StreamSubscription? _invalidationSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final results = await Future.wait([
        _service.getPlayoffTies(widget.playoffId),
        _service.getActiveSeason(),
      ]);
      if (!mounted) return;
      setState(() {
        _ties = results[0] as List<PlayoffTie>;
        _season = results[1] as String;
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
        tabs: const [
          Tab(text: 'Nosač'),
          Tab(text: 'Utakmice'),
        ],
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
              children: [
                BracketTab(ties: _ties),
                PlayoffMatchesTab(matchIds: _allMatchIds),
              ],
            ),
    );
  }
}
