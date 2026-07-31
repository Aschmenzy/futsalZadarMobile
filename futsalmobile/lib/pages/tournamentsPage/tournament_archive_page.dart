import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/tournament/tournament_data.dart';
import 'package:futsalmobile/pages/tournamentsPage/tournament_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';

/// Lists all finished tournaments; each entry opens the final bracket
/// with the podium (winner, runner-up, third place).
class TournamentArchivePage extends StatefulWidget {
  const TournamentArchivePage({super.key});

  @override
  State<TournamentArchivePage> createState() => _TournamentArchivePageState();
}

class _TournamentArchivePageState extends State<TournamentArchivePage> {
  final _service = FirebaseService();
  List<TournamentData> _tournaments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _service.getTournaments();
      if (!mounted) return;
      setState(() {
        _tournaments = all.where((t) => t.isFinished).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greška pri učitavanju arhive: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.ternary),
        title: Text(
          'Arhiva turnira',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            color: AppColors.ternary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
    if (_tournaments.isEmpty) {
      return Center(
        child: Text(
          'Nema završenih turnira',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            color: AppColors.ternaryGray,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tournaments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = _tournaments[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TournamentDetailsPage(tournament: t),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${t.seasonStamp} • ${t.bracketSize} momčadi',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
