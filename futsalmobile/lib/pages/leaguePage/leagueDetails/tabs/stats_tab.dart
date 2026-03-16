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
      final activeYellows = await _service.getPlayersByActiveYellows(
        widget.league.id,
        season: widget.season,
      );

      if (!mounted) return;
      setState(() {
        _topScorers = scorers;
        _topRedCards = redCards;
        _oneYellow = activeYellows['oneYellow']!;
        _twoYellows = activeYellows['twoYellows']!;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              // 1. Top Scorers
              _buildStatCard(
                title: 'Vodeći strijelci u lizi',
                players: _topScorers,
                trailing: (p) => _statWithIcon(
                  label: '${p.totalGoals.toInt()}',
                  icon: 'assets/icons/stats/SoccerBall.png',
                ),
              ),
              const SizedBox(height: 10),

              // 2. Top Red Cards
              _buildStatCard(
                title: 'Vodeći po crvenim kartonima',
                players: _topRedCards,
                trailing: (p) =>
                    _statWithRedCard(label: '${p.redCards.toInt()}'),
              ),
              const SizedBox(height: 10),

              // 3. Top Yellow Cards
              _buildStatCard(
                title: 'Vodeći po žutim kartonima',
                players: _topScorers, // replace with your yellow card list
                trailing: (p) =>
                    _statWithYellowCard(label: '${p.totalGoals.toInt()}'),
              ),
              const SizedBox(height: 10),

              // 4. 2nd Accumulated Yellow
              _buildStatCard(
                title: '2. Akumulirani žuti karton',
                players: _twoYellows,
                trailing: (p) => Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/stats/yellowCard.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                emptyText: 'Nema igrača s aktivnim žutim kartonima',
              ),
              const SizedBox(height: 10),

              // 5. 1st Accumulated Yellow
              _buildStatCard(
                title: '1. Akumulirani žuti karton',
                players: _oneYellow,
                trailing: (p) => Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/stats/yellowCard.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                emptyText: 'Nema igrača s aktivnim žutim kartonima',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
  // ── Card container ───────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String title,
    Color? titleColor,
    IconData? titleIcon,
    required List<PlayerStatsData> players,
    required Widget Function(PlayerStatsData) trailing,
    String emptyText = 'Nema dostupnih statistika',
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(
                    titleIcon,
                    size: 16,
                    color: titleColor ?? Colors.black87,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: titleColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // Body
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            )
          else if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                emptyText,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF0F0F0),
                indent: 14,
                endIndent: 14,
              ),
              itemBuilder: (context, index) =>
                  _playerRow(players[index], trailing),
            ),
        ],
      ),
    );
  }

  // ── Player row ───────────────────────────────────────────────────────────────

  Widget _playerRow(
    PlayerStatsData player,
    Widget Function(PlayerStatsData) trailing,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Player photo
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_withBg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + club
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.playerFullName,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/clubLogo/dinamo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      player.clubName,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trailing widget (stat or card pips)
          trailing(player),
        ],
      ),
    );
  }

  /// Bold number + small circular asset icon (e.g. soccer ball)
  Widget _statWithIcon({required String label, required String icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
          child: ClipOval(child: Image.asset(icon, fit: BoxFit.cover)),
        ),
      ],
    );
  }

  /// Bold number + single yellow card shape (yellow leaderboard)
  Widget _statWithYellowCard({required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),

        Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/stats/yellowCard.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statWithRedCard({required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),

        Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/stats/Foul.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
