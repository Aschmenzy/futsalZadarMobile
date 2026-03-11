import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/league_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class StatisticsTab extends StatefulWidget {
  final LeagueData league;
  final String season;

  const StatisticsTab({super.key, required this.league, required this.season});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final _service = FirebaseService();
  List<PlayerStatsData> _topScorers = [];
  List<PlayerStatsData> _topRedCards = [];
  List<PlayerStatsData> _topYellowCards = [];
  List<PlayerStatsData> _oneYellow = [];
  List<PlayerStatsData> _twoYellows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final scorers = await _service.getLeadingPlayersByGoals(
        widget.league.id,
        season: widget.season,
      );
      final redCards = await _service.getLeadingPlayersByRedCards(
        widget.league.id,
        season: widget.season,
      );
      final yellowCards = await _service.getLeadingPlayersByYellowCards(
        widget.league.id,
        season: widget.season,
      );
      final activeYellows = await _service.getPlayersByActiveYellows(
        widget.league.id,
        season: widget.season,
      );

      if (!mounted) return;
      setState(() {
        _topScorers = scorers;
        _topRedCards = redCards;
        _topYellowCards = yellowCards;
        _oneYellow = activeYellows['oneYellow']!;
        _twoYellows = activeYellows['twoYellows']!;
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
              _buildCard(
                title: 'Strijelci',
                players: _topScorers,
                statValue: (p) => '${p.totalGoals.toInt()}',
              ),
              const SizedBox(height: 12),
              _buildCard(
                title: 'Crveni kartoni',
                players: _topRedCards,
                statValue: (p) => '${p.redCards.toInt()}',
              ),
              const SizedBox(height: 12),
              _buildCard(
                title: 'Žuti kartoni',
                players: _topYellowCards,
                statValue: (p) => '${p.yellowCards.toInt()}',
              ),
              const SizedBox(height: 12),
              _buildSimpleYellowCard(
                title: 'Pred isključenjem (2 žuta)',
                players: _twoYellows,
                count: 2,
                labelColor: Colors.amber.shade700,
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.amber,
              ),
              const SizedBox(height: 12),
              _buildSimpleYellowCard(
                title: 'Upozorenje (1 žuti)',
                players: _oneYellow,
                count: 1,
                labelColor: Colors.orange,
                icon: Icons.info_outline,
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<PlayerStatsData> players,
    required String Function(PlayerStatsData) statValue,
  }) {
    return Card(
      elevation: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _cardHeader(),
            const SizedBox(height: 10),
            _sectionTitle(title),
            const SizedBox(height: 6),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            else if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nema dostupnih statistika'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) =>
                    _scorerRow(index + 1, players[index], statValue),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleYellowCard({
    required String title,
    required List<PlayerStatsData> players,
    required int count,
    required Color labelColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _cardHeader(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            else if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nema igrača s aktivnim žutim kartonima'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) =>
                    _yellowRow(players[index], count),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader() {
    return Row(
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
            fontFamily: AppFonts.roboto.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.roboto.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.ternaryGray,
        ),
      ),
    );
  }

  Widget _scorerRow(
    int rank,
    PlayerStatsData player,
    String Function(PlayerStatsData) statValue,
  ) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                '$rank.',
                style: TextStyle(
                  fontFamily: AppFonts.roboto.fontFamily,
                  fontSize: 13,
                  color: AppColors.ternaryGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                Text(
                  player.playerFullName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.roboto.fontFamily,
                  ),
                ),
                Text(
                  player.clubName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ternaryGray,
                    fontFamily: AppFonts.roboto.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          Text(
            statValue(player),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _yellowRow(PlayerStatsData player, int count) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  count,
                  (_) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(Icons.rectangle, color: Colors.amber, size: 16),
                  ),
                ),
              ),
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
                Text(
                  player.playerFullName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.roboto.fontFamily,
                  ),
                ),
                Text(
                  player.clubName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ternaryGray,
                    fontFamily: AppFonts.roboto.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
