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
  MatchData? _nextMatch;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getAllMatches(widget.league.id, season: widget.season),
        _service.getNextMatch(widget.league.id, season: widget.season),
      ]);

      if (!mounted) return;
      setState(() {
        _matches = results[0] as List<MatchData>;
        _nextMatch = results[1] as MatchData?;
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

  String _formatDate(String matchDate) {
    // '2026-01-24' → '24/01/26'
    final parts = matchDate.split('-');
    if (parts.length != 3) return matchDate;
    return '${parts[2]}/${parts[1]}/${parts[0].substring(2)}';
  }

  String _formatTime(String matchDate, String matchTime) {
    final date = DateTime.tryParse(matchDate);
    if (date == null) return matchTime;
    final now = DateTime.now();
    // If match date+time is in the past → FT
    final matchDateTime = DateTime.tryParse('$matchDate $matchTime') ?? date;
    return matchDateTime.isBefore(now) ? 'FT' : matchTime;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: AppColors.background),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.ternary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Header
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo_withBg.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.league.name,
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Content
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else if (_matches.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nema utakmica'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _matches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final match = _matches[index];
                            final isNext =
                                _nextMatch != null &&
                                match.matchId == _nextMatch!.matchId;
                            return _matchRow(
                              _formatDate(match.matchDate),
                              _formatTime(match.matchDate, match.matchTime),
                              match.homeTeam,
                              match.awayTeam,
                              match.homeTeamLogo,
                              match.awayTeamLogo,
                              match.homeTeamGoals.toString(),
                              match.awayTeamGoals.toString(),
                              isNext: isNext,
                            );
                          },
                        ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports, size: 16),
                  )
                : Image.asset(logo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: AppFonts.roboto,
          ),
        ),
      ],
    );
  }
}
