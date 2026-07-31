import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/models/tournament/tournament_data.dart';
import 'package:futsalmobile/pages/tournamentsPage/tabs/tournament_teams_tab.dart';
import 'package:futsalmobile/pages/tournamentsPage/widgets/tournament_bracket_widget.dart';
import 'package:futsalmobile/pages/tournamentsPage/widgets/tournament_podium.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class TournamentDetailsPage extends StatefulWidget {
  final TournamentData tournament;

  const TournamentDetailsPage({super.key, required this.tournament});

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage>
    with SingleTickerProviderStateMixin {
  final _service = FirebaseService();
  late final TabController _tabController;

  List<PlayoffTie> _ties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTies() async {
    try {
      final ties = await _service.getTournamentTies(widget.tournament.id);
      if (!mounted) return;
      setState(() {
        _ties = ties;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greška pri učitavanju ždrijeba: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.ternary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.name,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.ternary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              t.isFinished
                  ? 'Turnir • ${t.seasonStamp} • Završen'
                  : 'Turnir • ${t.seasonStamp}',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentYellow,
          labelColor: AppColors.ternary,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Ždrijeb'),
            Tab(text: 'Momčadi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBracketTab(),
          TournamentTeamsTab(tournamentId: t.id),
        ],
      ),
    );
  }

  Widget _buildBracketTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (widget.tournament.isFinished)
          TournamentPodium(
            ties: _ties,
            thirdPlace: widget.tournament.thirdPlace,
          ),
        Expanded(
          child: TournamentBracketWidget(
            bracketSize: widget.tournament.bracketSize,
            thirdPlace: widget.tournament.thirdPlace,
            ties: _ties,
          ),
        ),
      ],
    );
  }
}
