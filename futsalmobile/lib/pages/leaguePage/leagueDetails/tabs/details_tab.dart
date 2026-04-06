import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/next_match.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';
import 'package:futsalmobile/models/league_data.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:intl/intl.dart';

class DetailsTab extends StatefulWidget {
  final LeagueData league;
  final String season;
  const DetailsTab({super.key, required this.league, required this.season});

  @override
  State<DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> {
  final _service = FirebaseService();
  List<ClubData> _clubs = [];
  MatchData? _nextMatch;
  bool _loading = true;
  int _currentRound = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getClubsByLeague(widget.league.id),
        _service.getNextMatch(widget.league.id, season: widget.season),
        _service.getCurrentRound(widget.league.id, season: widget.season),
      ]);

      if (!mounted) return;
      setState(() {
        _clubs = results[0] as List<ClubData>;
        _nextMatch = results[1] as MatchData?;
        _currentRound = results[2] as int;
        _loading = false;
      });
    } catch (e) {
      debugPrint('FIREBASE ERROR: $e');
      if (!mounted) return;

      setState(() {
        _error = 'Greska pri ucitavanju podataka $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dateFormat = DateFormat('d.M.yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenHeight),
        child: ColoredBox(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16, right: 16.0),
            child: Column(
              children: [
                SponsorsBanner(),
                SizedBox(height: screenHeight * 0.02),

                // LIGA PROGRESS CARD
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ternary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 44,
                          height: 44,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.league.name}, Runda: $_currentRound',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _currentRound / 22,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormat.format(LeagueData.startDate),
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontSize: 12,
                                      color: AppColors.ternaryGray,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(LeagueData.endDate),
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontSize: 12,
                                      color: AppColors.ternaryGray,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // SLJEDECA UTAKMICA CARD
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : NextMatch(match: _nextMatch),

                SizedBox(height: screenHeight * 0.01),

                // BROJ EKIPA CARD
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: screenHeight * 0.08,
                    decoration: BoxDecoration(
                      color: AppColors.ternary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Broj ekipa',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  color: AppColors.ternaryGray,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                '${_clubs.length}',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // VISA LIGA
                if (widget.league.higherLeagueName != null)
                  _buildRelatedLeagueCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    label: 'Visa liga',
                    leagueName: widget.league.higherLeagueName!,
                  ),

                // NIZA LIGA
                if (widget.league.lowerLeagueName != null)
                  _buildRelatedLeagueCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    label: 'Niza liga',
                    leagueName: widget.league.lowerLeagueName!,
                  ),

                SizedBox(height: screenHeight * 0.01),

                // ERROR PORUKA
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedLeagueCard({
    required double screenWidth,
    required double screenHeight,
    required String label,
    required String leagueName,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: double.infinity,
          height: screenHeight * 0.09,
          decoration: BoxDecoration(
            color: AppColors.ternary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', scale: 2),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      leagueName,
                      style: TextStyle(fontFamily: AppFonts.roboto),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
