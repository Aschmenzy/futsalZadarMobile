import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/clubStanding.dart';
import 'package:futsalmobile/models/favorite_item.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';
import 'package:futsalmobile/services/auth_service.dart';
import 'package:futsalmobile/services/favorites_service.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.asset('assets/images/logo.png', scale: 0.7)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Favoriti',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(child: _FavoritesContent()),
          ],
        ),
      ),
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────────

class _FavoritesContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (AuthService.uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final service = FavoritesService();
    return StreamBuilder<List<FavoriteItem>>(
      stream: service.starredStream,
      builder: (context, starSnap) {
        return StreamBuilder<List<FavoriteItem>>(
          stream: service.matchNotificationsStream,
          builder: (context, matchSnap) {
            if (starSnap.connectionState == ConnectionState.waiting ||
                matchSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (starSnap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Greška: ${starSnap.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final starred = starSnap.data ?? [];
            final matches = matchSnap.data ?? [];

            final leagues = starred.where((i) => i.type == 'league').toList();
            final clubs = starred.where((i) => i.type == 'club').toList();
            final players = starred.where((i) => i.type == 'player').toList();

            if (leagues.isEmpty &&
                clubs.isEmpty &&
                players.isEmpty &&
                matches.isEmpty) {
              return _EmptyState();
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (leagues.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.shield_outlined,
                    title: 'Omiljene lige',
                  ),
                  ...leagues.map((item) => _LeagueFavoriteCard(item: item)),
                ],
                if (clubs.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.people_outline,
                    title: 'Omiljeni timovi',
                  ),
                  ...clubs.map((item) => _ClubFavoriteCard(item: item)),
                ],
                if (players.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.directions_run,
                    title: 'Omiljeni igrači',
                  ),
                  ...players.map((item) => _PlayerFavoriteCard(item: item)),
                ],
                if (matches.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.notifications_outlined,
                    title: 'Praćene utakmice',
                  ),
                  ...matches.map((item) => _MatchNotifCard(item: item)),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Remove button ──────────────────────────────────────────────────────────────

class _RemoveButton extends StatelessWidget {
  final String entityId;
  const _RemoveButton({required this.entityId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FavoritesService().removeFromFavorites(entityId),
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 14, color: Colors.black54),
      ),
    );
  }
}

// ── League card ────────────────────────────────────────────────────────────────

class _LeagueFavoriteCard extends StatefulWidget {
  final FavoriteItem item;
  const _LeagueFavoriteCard({required this.item});

  @override
  State<_LeagueFavoriteCard> createState() => _LeagueFavoriteCardState();
}

class _LeagueFavoriteCardState extends State<_LeagueFavoriteCard> {
  final _service = FirebaseService();
  int? _clubCount;
  ClubStanding? _leader;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getClubCount(widget.item.leagueId),
        _service.getBestClubInLeague(widget.item.leagueId),
      ]);
      if (!mounted) return;
      setState(() {
        _clubCount = results[0] as int;
        _leader = results[1] as ClubStanding?;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo_withBg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.people_outline,
                      label: 'Broj timova:',
                      value: _clubCount != null ? '$_clubCount' : '—',
                    ),
                    const SizedBox(width: 16),
                    _InfoChip(
                      icon: Icons.emoji_events_outlined,
                      label: 'Vodeći tim:',
                      value: _leader?.clubName ?? '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RemoveButton(entityId: item.entityId),
        ],
      ),
    );
  }
}

// ── Club card ──────────────────────────────────────────────────────────────────

class _ClubFavoriteCard extends StatefulWidget {
  final FavoriteItem item;
  const _ClubFavoriteCard({required this.item});

  @override
  State<_ClubFavoriteCard> createState() => _ClubFavoriteCardState();
}

class _ClubFavoriteCardState extends State<_ClubFavoriteCard> {
  final _service = FirebaseService();
  List<MatchData> _lastFive = [];
  MatchData? _nextMatch;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getAllMatches(widget.item.leagueId),
        _service.getNextMatchByClub(widget.item.leagueId, widget.item.name),
      ]);
      if (!mounted) return;
      final all = results[0] as List<MatchData>;
      final finished = all
          .where(
            (m) =>
                m.isFinished &&
                (m.homeTeam == widget.item.name ||
                    m.awayTeam == widget.item.name),
          )
          .take(5)
          .toList();
      setState(() {
        _lastFive = finished;
        _nextMatch = results[1] as MatchData?;
      });
    } catch (_) {}
  }

  String _result(MatchData m) {
    final isHome = m.homeTeam == widget.item.name;
    final myGoals = isHome ? m.homeTeamGoals : m.awayTeamGoals;
    final theirGoals = isHome ? m.awayTeamGoals : m.homeTeamGoals;
    if (myGoals > theirGoals) return 'W';
    if (myGoals == theirGoals) return 'D';
    return 'L';
  }

  Color _resultColor(String r) {
    if (r == 'W') return AppColors.gameWon;
    if (r == 'D') return AppColors.gameDraw;
    return AppColors.liveGame;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircleAvatar(imageUrl: item.imageUrl, name: item.name, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.leagueName,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 12,
                        color: AppColors.ternaryGray,
                      ),
                    ),
                  ],
                ),
              ),
              _RemoveButton(entityId: item.entityId),
            ],
          ),
          if (_lastFive.isNotEmpty || _nextMatch != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: last matches
                if (_lastFive.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zadnje utakmice',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 11,
                            color: AppColors.ternaryGray,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: _lastFive.map((m) {
                            final r = _result(m);
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _resultColor(r),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                r,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                // Right: next match
                if (_nextMatch != null)
                  _NextMatchColumn(match: _nextMatch!, clubName: item.name),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Player card ────────────────────────────────────────────────────────────────

class _PlayerFavoriteCard extends StatefulWidget {
  final FavoriteItem item;
  const _PlayerFavoriteCard({required this.item});

  @override
  State<_PlayerFavoriteCard> createState() => _PlayerFavoriteCardState();
}

class _PlayerFavoriteCardState extends State<_PlayerFavoriteCard> {
  final _service = FirebaseService();
  PlayerStatsData? _stats;
  MatchData? _nextMatch;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final statsFuture = _service
        .getPlayerStatsByPlayerId(widget.item.leagueId, widget.item.entityId)
        .catchError((_) => null);
    final nextFuture = widget.item.clubName != null
        ? _service
              .getNextMatchByClub(widget.item.leagueId, widget.item.clubName)
              .catchError((_) => null)
        : Future<MatchData?>.value(null);

    final stats = await statsFuture;
    final next = await nextFuture;
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _nextMatch = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircleAvatar(imageUrl: item.imageUrl, name: item.name, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.clubName != null)
                      Row(
                        children: [
                          if (item.clubImageUrl != null &&
                              item.clubImageUrl!.isNotEmpty)
                            ClipOval(
                              child: Image.network(
                                item.clubImageUrl!,
                                width: 18,
                                height: 18,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            item.clubName!,
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
              _RemoveButton(entityId: item.entityId),
            ],
          ),
          if (_stats != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatBadge(
                  value: _stats!.totalGoals,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  value: _stats!.yellowCards,
                  color: AppColors.accentYellow,
                ),
                const SizedBox(width: 8),
                _StatBadge(value: _stats!.redCards, color: AppColors.accent),
              ],
            ),
          ],
          if (_nextMatch != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _NextMatchColumn(
                match: _nextMatch!,
                clubName: item.clubName ?? '',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Match notification card ────────────────────────────────────────────────────

class _MatchNotifCard extends StatelessWidget {
  final FavoriteItem item;
  const _MatchNotifCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications,
            color: AppColors.accentYellow,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          _RemoveButton(entityId: item.entityId),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

class _NextMatchColumn extends StatelessWidget {
  final MatchData match;
  final String clubName;
  const _NextMatchColumn({required this.match, required this.clubName});

  @override
  Widget build(BuildContext context) {
    final isHome = match.homeTeam == clubName;
    final opponent = isHome ? match.awayTeam : match.homeTeam;
    final date = _formatDate(match.matchDate);
    final time = _formatTime(match.matchTime);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Sljedeća utakmica',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 11,
            color: AppColors.ternaryGray,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'VS $opponent',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.end,
        ),
        const SizedBox(height: 2),
        Text(
          time.isNotEmpty ? '$date  $time' : date,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 11,
            color: AppColors.ternaryGray,
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.day}.${d.month}.${d.year}.';
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String time) {
    try {
      final t = DateTime.tryParse(time);
      if (t == null) return '';
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _StatBadge extends StatelessWidget {
  final num value;
  final Color color;
  const _StatBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _CircleAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;
  const _CircleAvatar({
    required this.imageUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : name.isNotEmpty
        ? name[0]
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F0F8),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.32,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.secondary),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11,
                color: AppColors.ternaryGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border_rounded, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nema favorita',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pritisni zvjezdicu na ligi, klubu ili igraču\nda ga dodaš ovdje.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
