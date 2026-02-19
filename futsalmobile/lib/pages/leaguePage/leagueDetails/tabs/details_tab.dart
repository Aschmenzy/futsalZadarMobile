import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';
import 'package:futsalmobile/pages/leaguePage/models/league_data.dart';
import 'package:futsalmobile/pages/leaguePage/models/club_data.dart';
import 'package:intl/intl.dart';

class DetailsTab extends StatefulWidget {
  final LeagueData league;
  const DetailsTab({super.key, required this.league});

  @override
  State<DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> {
  final _service = FirebaseService();
  List<ClubData> _clubs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final clubs = await _service.getClubsByLeague(widget.league.id);
      setState(() {
        _clubs = clubs;
        _loading = false;
      });
    } catch (e) {
      debugPrint('FIREBASE ERROR: $e');
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: AppColors.background),
          child: Column(
            children: [
              SponsorsBanner(),
              SizedBox(height: screenHeight * 0.02),

              //  LIGA PROGRESS CARD
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: screenWidth * 0.85,
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
                              '${widget.league.name}, Runda ${widget.league.currentRound}',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: widget.league.currentRound / 22,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormat.format(LeagueData.startDate),
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto.fontFamily,
                                    fontSize: 12,
                                    color: AppColors.ternaryGray,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(LeagueData.endDate),
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto.fontFamily,
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
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: screenWidth * 0.85,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ternary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            "Sljedeca utakmica",
                            style: TextStyle(
                              fontFamily: AppFonts.roboto.fontFamily,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTeamColumn(
                            teamName: "Hajduk",
                            logoPath: 'assets/images/clubLogo/hajduk.png',
                          ),
                          Column(
                            children: [
                              Text(
                                "Za 7 dana",
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "18.01.2026. 19:00",
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto.fontFamily,
                                  fontSize: 13,
                                  color: AppColors.ternaryGray,
                                ),
                              ),
                            ],
                          ),
                          _buildTeamColumn(
                            teamName: "Dinamo",
                            logoPath: 'assets/images/clubLogo/dinamo.png',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              //  BROJ EKIPA CARD
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: screenWidth * 0.85,
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
                              "Broj ekipa",
                              style: TextStyle(
                                fontFamily: AppFonts.roboto.fontFamily,
                                color: AppColors.ternaryGray,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              '${_clubs.length}',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              //  VISA LIGA
              if (widget.league.higherLeagueName != null)
                _buildRelatedLeagueCard(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  label: "Visa liga",
                  leagueName: widget.league.higherLeagueName!,
                ),

              //  NIZA LIGA
              if (widget.league.lowerLeagueName != null)
                _buildRelatedLeagueCard(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  label: "Niza liga",
                  leagueName: widget.league.lowerLeagueName!,
                ),

              SizedBox(height: screenHeight * 0.01),

              //  ERROR PORUKA
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
    );
  }

  Widget _buildTeamColumn({
    required String teamName,
    required String logoPath,
  }) {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            logoPath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          teamName,
          style: TextStyle(
            fontFamily: AppFonts.roboto.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          width: screenWidth * 0.85,
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
                    fontFamily: AppFonts.roboto.fontFamily,
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
                      style: TextStyle(fontFamily: AppFonts.roboto.fontFamily),
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
