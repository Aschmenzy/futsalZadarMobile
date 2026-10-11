import 'package:flutter/material.dart';
import 'package:futsalmobile/widgets/cached_image.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';
import 'package:futsalmobile/pages/playerDetailsPage/player_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/pro_badge.dart';

/// Player statistics for a league season. With [clubId] / [clubName] set it
/// narrows to that club's players and leads with who is suspended right now.
class StatisticsTab extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  final String season;
  final String? clubId;
  final String? clubName;

  const StatisticsTab({
    super.key,
    required this.leagueId,
    required this.leagueName,
    required this.season,
    this.clubId,
    this.clubName,
  });

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
  List<PlayerStatsData> _threeYellows = [];

  /// Club view only: players banned right now, and playerId -> last round
  /// they miss.
  List<PlayerStatsData> _suspended = [];
  Map<String, int> _suspendedUntil = {};

  bool _loading = true;
  String? _error;

  /// Club logos keyed by club id and by normalised club name.
  Map<String, String> _clubLogos = {};

  /// Player profile photos keyed by player id.
  Map<String, String> _playerPhotos = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadClubLogos();
  }

  static String _nameKey(String name) => name.trim().toLowerCase();

  bool get _isClubView => widget.clubId != null && widget.clubName != null;

  /// Loads club logos for the league so player rows can show the real crest,
  /// plus the players' own profile photos for the row avatar.
  Future<void> _loadClubLogos() async {
    final logos = <String, String>{};
    final photos = <String, String>{};
    try {
      final clubs = await _service.getClubsByLeague(widget.leagueId);
      for (final club in clubs) {
        if (_isClubView && club.id != widget.clubId) continue;
        // Players come from the same cached payload the profile page uses,
        // so this costs no extra request.
        try {
          final players = await _service.getPlayersByClub(
            widget.leagueId,
            club.id,
          );
          for (final p in players) {
            if (p.profilePicture.isNotEmpty) photos[p.id] = p.profilePicture;
          }
        } catch (_) {}
        if (club.clubProfileImg.isEmpty) continue;
        logos[club.id] = club.clubProfileImg;
        logos[_nameKey(club.clubName)] = club.clubProfileImg;
      }
    } catch (_) {}

    // Fallback: standings also carry a logo per club.
    try {
      final standings = await _service.getAllClubsInLeague(
        widget.leagueId,
        season: widget.season,
      );
      for (final s in standings) {
        if (s.clubLogo.isEmpty) continue;
        logos.putIfAbsent(s.clubId, () => s.clubLogo);
        logos.putIfAbsent(_nameKey(s.clubName), () => s.clubLogo);
      }
    } catch (_) {}

    if (!mounted || (logos.isEmpty && photos.isEmpty)) return;
    setState(() {
      if (logos.isNotEmpty) _clubLogos = logos;
      if (photos.isNotEmpty) _playerPhotos = photos;
    });
  }

  /// Resolves a player's club logo: value from the stats payload first,
  /// then a lookup by club id, then by club name.
  String? _logoFor(PlayerStatsData player) {
    if (player.clubLogo.isNotEmpty) return player.clubLogo;
    final byId = player.clubId.isNotEmpty ? _clubLogos[player.clubId] : null;
    return byId ?? _clubLogos[_nameKey(player.clubName)];
  }

  Future<void> _loadData() async {
    try {
      final Map<String, List<PlayerStatsData>> stats;
      var suspended = <PlayerStatsData>[];
      var suspendedUntil = <String, int>{};
      if (_isClubView) {
        final players = await _service.getClubPlayerStats(
          widget.leagueId,
          clubId: widget.clubId!,
          clubName: widget.clubName!,
          season: widget.season,
        );
        stats = FirebaseService.groupPlayerStats(players);
        try {
          suspendedUntil = await _service.getSuspendedPlayers(
            widget.leagueId,
            clubId: widget.clubId!,
            clubName: widget.clubName!,
            season: widget.season,
          );
        } catch (_) {}
        suspended =
            players
                .where((p) => suspendedUntil.containsKey(p.playerId))
                .toList()
              ..sort(
                (a, b) => suspendedUntil[b.playerId]!.compareTo(
                  suspendedUntil[a.playerId]!,
                ),
              );
      } else {
        stats = await _service.getAllLeaguePlayerStats(
          widget.leagueId,
          season: widget.season,
        );
      }

      if (!mounted) return;
      setState(() {
        _suspended = suspended;
        _suspendedUntil = suspendedUntil;
        _topScorers = stats['topScorers']!;
        _topRedCards = stats['topRedCards']!;
        _topYellowCards = stats['topYellowCards']!;
        _oneYellow = stats['oneYellow']!;
        _twoYellows = stats['twoYellows']!;
        _threeYellows = stats['threeYellows']!;
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
              // 0. Suspended players (club view)
              if (_isClubView) ...[
                _buildStatCard(
                  title: 'Suspendirani igrači',
                  titleIcon: Icons.block,
                  titleColor: _suspendedColor,
                  players: _suspended,
                  trailing: (p) => _suspensionLabel(p),
                  emptyText: 'Nema suspendiranih igrača',
                ),
                const SizedBox(height: 10),
              ],

              // 1. Top Scorers
              _buildStatCard(
                title: _isClubView ? 'Strijelci' : 'Vodeći strijelci u ligi',
                players: _topScorers,
                trailing: (p) => _statWithIcon(
                  label: '${p.totalGoals.toInt()}',
                  icon: 'assets/icons/stats/SoccerBall.png',
                ),
              ),
              const SizedBox(height: 10),

              // 2. Top Red Cards
              _buildStatCard(
                title: _isClubView
                    ? 'Crveni kartoni'
                    : 'Vodeći po crvenim kartonima',
                players: _topRedCards,
                trailing: (p) =>
                    _statWithRedCard(label: '${p.redCards.toInt()}'),
              ),
              const SizedBox(height: 10),

              // 3. Top Yellow Cards
              _buildStatCard(
                title: _isClubView
                    ? 'Žuti kartoni'
                    : 'Vodeći po žutim kartonima',
                players: _topYellowCards,
                trailing: (p) =>
                    _statWithYellowCard(label: '${p.yellowCards.toInt()}'),
              ),
              const SizedBox(height: 10),

              // 4. 3rd Accumulated Yellow
              _buildStatCard(
                title: '3. Akumulirani žuti karton',
                players: _threeYellows,
                trailing: (_) => _yellowCardIcon(),
                emptyText: 'Nema igrača s aktivnim žutim kartonima',
              ),
              const SizedBox(height: 10),

              // 5. 2nd Accumulated Yellow
              _buildStatCard(
                title: '2. Akumulirani žuti karton',
                players: _twoYellows,
                trailing: (_) => _yellowCardIcon(),
                emptyText: 'Nema igrača s aktivnim žutim kartonima',
              ),
              const SizedBox(height: 10),

              // 6. 1st Accumulated Yellow
              _buildStatCard(
                title: '1. Akumulirani žuti karton',
                players: _oneYellow,
                trailing: (_) => _yellowCardIcon(),
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

  /// Number of players shown in a card before "Prikaži sve".
  static const _previewCount = 5;

  Widget _buildStatCard({
    required String title,
    Color? titleColor,
    IconData? titleIcon,
    required List<PlayerStatsData> players,
    required Widget Function(PlayerStatsData) trailing,
    String emptyText = 'Nema dostupnih statistika',
  }) {
    final canOpen = !_loading && _error == null && players.isNotEmpty;
    final preview = players.take(_previewCount).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canOpen
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _StatListPage(
                      title: title,
                      players: players,
                      rowBuilder: (p) => _playerRow(p, trailing),
                    ),
                  ),
                )
              : null,
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
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: titleColor ?? Colors.black87,
                        ),
                      ),
                    ),
                    if (canOpen) ...[
                      Text(
                        'Prikaži sve (${players.length})',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
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
                  itemCount: preview.length,
                  separatorBuilder: (_, _) => const _RowDivider(),
                  itemBuilder: (context, index) =>
                      _playerRow(preview[index], trailing),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Player row ───────────────────────────────────────────────────────────────

  Widget _playerRow(
    PlayerStatsData player,
    Widget Function(PlayerStatsData) trailing,
  ) {
    return InkWell(
      onTap: () => _openPlayer(player),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Player photo
            SizedBox(width: 52, height: 52, child: _playerPhoto(player)),

            const SizedBox(width: 12),

            // Name + club
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.playerFullName,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (player.isProfessional) ...[
                        const SizedBox(width: 6),
                        const ProBadge(),
                      ],
                    ],
                  ),
                  if (_isClubView) ...[
                    if (_suspendedUntil.containsKey(player.playerId)) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Suspendiran',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: _suspendedColor,
                        ),
                      ),
                    ],
                  ] else ...[
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
                          child: ClipOval(child: _clubLogo(player)),
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
                ],
              ),
            ),

            // Trailing widget (stat or card pips)
            trailing(player),
          ],
        ),
      ),
    );
  }

  bool _openingPlayer = false;

  /// Opens the player profile. Stats rows only carry ids, so the full player
  /// and club records are resolved from the cached league data first.
  Future<void> _openPlayer(PlayerStatsData stats) async {
    if (_openingPlayer) return;
    _openingPlayer = true;
    final leagueId = widget.leagueId;

    ClubData? club;
    PlayerData? player;
    try {
      final clubs = await _service.getClubsByLeague(leagueId);
      club =
          clubs.where((c) => c.id == stats.clubId).firstOrNull ??
          clubs
              .where((c) => _nameKey(c.clubName) == _nameKey(stats.clubName))
              .firstOrNull;

      if (club != null) {
        final players = await _service.getPlayersByClub(leagueId, club.id);
        player = players.where((p) => p.id == stats.playerId).firstOrNull;
      }

      // The player may have changed clubs since these stats — scan the league.
      if (player == null) {
        for (final c in clubs) {
          final players = await _service.getPlayersByClub(leagueId, c.id);
          final found = players
              .where((p) => p.id == stats.playerId)
              .firstOrNull;
          if (found != null) {
            player = found;
            club = c;
            break;
          }
        }
      }
    } catch (_) {}

    _openingPlayer = false;
    if (!mounted) return;

    if (player == null || club == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil igrača trenutno nije dostupan')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerDetailsPage(
          player: player!,
          leagueId: leagueId,
          clubData: club!,
          leaugeName: widget.leagueName,
        ),
      ),
    );
  }

  /// Row avatar: the player's own photo when there is one, otherwise the
  /// plain app logo (no coloured disc behind it).
  Widget _playerPhoto(PlayerStatsData player) {
    final url = player.playerId.isEmpty ? null : _playerPhotos[player.playerId];
    if (url == null || url.isEmpty) return _playerPhotoFallback();
    return ClipOval(
      child: CachedImage(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_) => _playerPhotoFallback(),
      ),
    );
  }

  Widget _playerPhotoFallback() =>
      Image.asset('assets/images/logo.png', fit: BoxFit.contain);

  /// Club crest for a player row, with a neutral fallback icon.
  Widget _clubLogo(PlayerStatsData player) {
    final url = _logoFor(player);
    if (url == null || url.isEmpty) return _clubLogoFallback();
    return CachedImage(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_) => _clubLogoFallback(),
    );
  }

  Widget _clubLogoFallback() => Center(
    child: Icon(Icons.shield_outlined, size: 13, color: Colors.grey.shade500),
  );

  static const _suspendedColor = Color(0xFFD32F2F);

  /// "do 5. kola" - last round the suspended player misses.
  Widget _suspensionLabel(PlayerStatsData player) {
    final until = _suspendedUntil[player.playerId];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _suspendedColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        until == null ? 'Suspendiran' : 'do $until. kola',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: _suspendedColor,
        ),
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

  /// Plain yellow card icon (accumulated yellow sections)
  Widget _yellowCardIcon() {
    return Container(
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    color: Color(0xFFF0F0F0),
    indent: 14,
    endIndent: 14,
  );
}

/// Full list of players for one stats section.
class _StatListPage extends StatelessWidget {
  final String title;
  final List<PlayerStatsData> players;
  final Widget Function(PlayerStatsData) rowBuilder;

  const _StatListPage({
    required this.title,
    required this.players,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE4E4E4), width: 1),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: players.length,
            separatorBuilder: (_, _) => const _RowDivider(),
            itemBuilder: (_, index) => rowBuilder(players[index]),
          ),
        ),
      ),
    );
  }
}
