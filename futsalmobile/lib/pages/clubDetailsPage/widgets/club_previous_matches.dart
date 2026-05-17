import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class ClubPreviousMatches extends StatefulWidget {
  final String leagueId;
  final String clubName;

  const ClubPreviousMatches({
    super.key,
    required this.leagueId,
    required this.clubName,
  });

  @override
  State<ClubPreviousMatches> createState() => _ClubPreviousMatchesState();
}

class _ClubPreviousMatchesState extends State<ClubPreviousMatches> {
  final _service = FirebaseService();
  List<MatchData> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final matches = await _service.getRecentFinishedMatchesByClub(
        widget.leagueId,
        widget.clubName,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _result(MatchData m) {
    final isHome = m.homeTeam == widget.clubName;
    final scored = isHome ? m.homeTeamGoals : m.awayTeamGoals;
    final conceded = isHome ? m.awayTeamGoals : m.homeTeamGoals;
    if (scored > conceded) return 'W';
    if (scored < conceded) return 'L';
    return 'D';
  }

  Color _resultColor(String result) {
    switch (result) {
      case 'W':
        return AppColors.gameWon;
      case 'L':
        return AppColors.gameLost;
      default:
        return AppColors.ternaryGray;
    }
  }

  String _opponentLogo(MatchData m) {
    return m.homeTeam == widget.clubName ? m.awayTeamLogo : m.homeTeamLogo;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Prijašnje utakmice',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const SizedBox(
                height: 60,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nema odigranih utakmica',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    color: AppColors.ternaryGray,
                    fontSize: 13,
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _matches.map((m) {
                    final result = _result(m);
                    final color = _resultColor(result);
                    final logo = _opponentLogo(m);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: logo.isNotEmpty
                                ? Image.network(
                                    logo,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _fallbackLogo(),
                                  )
                                : _fallbackLogo(),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 32,
                            height: result == 'D' ? 10 : 48,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackLogo() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.sports_soccer, size: 16, color: AppColors.ternaryGray),
    );
  }
}
