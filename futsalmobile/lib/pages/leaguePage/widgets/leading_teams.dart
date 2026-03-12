import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/clubStanding.dart';

import 'package:futsalmobile/services/firebase_services.dart';

class LeadingTeams extends StatefulWidget {
  const LeadingTeams({super.key});

  @override
  State<LeadingTeams> createState() => _LeadingTeamsState();
}

class _LeadingTeamsState extends State<LeadingTeams> {
  final _service = FirebaseService();
  final Map<String, ClubStanding?> _leadingClubs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final leagues = ['liga1', 'liga2', 'liga3', 'liga4'];
    for (final id in leagues) {
      final club = await _service.getBestClubInLeague(id);
      if (mounted) {
        setState(() => _leadingClubs[id] = club);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vodeći timovi po ligama",
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ...['liga1', 'liga2', 'liga3', 'liga4'].map((leagueId) {
                  final club = _leadingClubs[leagueId];
                  final leagueLabel = leagueId
                      .replaceAll('liga', 'Liga ')
                      .replaceFirst('Liga ', 'Liga ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _TeamRow(
                      screenWidth: screenWidth,
                      clubName: club?.clubName ?? '-',
                      clubLogo: club?.clubLogo,
                      leagueLabel: leagueLabel,
                      points: club?.points ?? 0,
                      matchesPlayed: club?.matchesPlayed ?? 0,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.screenWidth,
    required this.clubName,
    required this.leagueLabel,
    required this.points,
    required this.matchesPlayed,
    this.clubLogo,
  });

  final double screenWidth;
  final String clubName;
  final String? clubLogo;
  final String leagueLabel;
  final int points;
  final int matchesPlayed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // logo
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: clubLogo != null && clubLogo!.isNotEmpty
              ? Image.network(
                  clubLogo!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),

        SizedBox(width: screenWidth * 0.025),

        // club name & league
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clubName,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                leagueLabel,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  color: AppColors.ternaryGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // points & matches
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$points bodova',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$matchesPlayed utakmica',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.shield, size: 20, color: Colors.grey),
    );
  }
}
