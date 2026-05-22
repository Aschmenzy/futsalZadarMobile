import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/pages/matchDetailsPage/match_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/utakmica_container.dart';

class PlayoffMatchesTab extends StatefulWidget {
  final List<String> matchIds;
  // Pre-loaded matches (group playoffs read directly from Firestore)
  final List<MatchData>? matches;

  const PlayoffMatchesTab({
    super.key,
    this.matchIds = const [],
    this.matches,
  });

  @override
  State<PlayoffMatchesTab> createState() => _PlayoffMatchesTabState();
}

class _PlayoffMatchesTabState extends State<PlayoffMatchesTab> {
  final _service = FirebaseService();

  List<MatchData> _matches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.matches != null) {
      _matches = widget.matches!;
      _loading = false;
    } else {
      _loadMatches();
    }
  }

  Future<void> _loadMatches() async {
    if (widget.matchIds.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait(
        widget.matchIds.map((id) => _service.getMatchDetail(id)),
      );
      if (!mounted) return;
      setState(() {
        _matches = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greška pri učitavanju utakmica: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Text(
          'Nema utakmica',
          style: TextStyle(fontFamily: AppFonts.roboto, color: Colors.grey),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.background,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchDetailsPage(match: match),
                ),
              ),
              child: UtakmicaContainer(
                matchStatus: match.status,
                team1Name: match.homeTeam,
                team2Name: match.awayTeam,
                team1Logo: match.homeTeamLogo,
                team2Logo: match.awayTeamLogo,
                team1Score: match.homeTeamGoals,
                team2Score: match.awayTeamGoals,
                matchTime: match.matchTime,
                matchDate: match.matchDate,
                showMatchDate: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
