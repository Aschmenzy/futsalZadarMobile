import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/favorite_item.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';
import 'package:futsalmobile/pages/playerDetailsPage/widgets/player_details_app_bar.dart';
import 'package:futsalmobile/pages/playerDetailsPage/widgets/stats_card.dart';
import 'package:futsalmobile/services/favorites_service.dart';
import 'package:futsalmobile/services/firebase_services.dart';

// clubId → logo URL resolved from the cached clubs data
typedef _LogoMap = Map<String, String>;

class PlayerDetailsPage extends StatefulWidget {
  final PlayerData player;
  final String leagueId;
  final String leaugeName;
  final ClubData clubData;

  const PlayerDetailsPage({
    super.key,
    required this.player,
    required this.leagueId,
    required this.clubData,
    required this.leaugeName,
  });

  @override
  State<PlayerDetailsPage> createState() => _PlayerDetailsPageState();
}

class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  final _service = FirebaseService();
  final _favService = FavoritesService();
  PlayerStatsData? _stats;
  bool _loading = true;
  _LogoMap _historyLogos = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadHistoryLogos();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _service.getPlayerStatsByPlayerId(
        widget.leagueId,
        widget.player.id,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // Resolves club logo URLs for each clubHistory entry from the cached clubs
  // data. Uses the existing Hive cache so no extra network reads are needed.
  Future<void> _loadHistoryLogos() async {
    final history = widget.player.clubHistory;
    if (history.isEmpty) return;

    final logos = <String, String>{};
    for (final entry in history) {
      if (logos.containsKey(entry.clubId) || entry.league.isEmpty) continue;
      try {
        final clubs = await _service.getClubsByLeague(entry.league);
        final club = clubs.where((c) => c.id == entry.clubId).firstOrNull;
        if (club != null && club.clubProfileImg.isNotEmpty) {
          logos[entry.clubId] = club.clubProfileImg;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _historyLogos = logos);
  }

  FavoriteItem _buildFavoriteItem({bool starred = false, bool notif = false}) =>
      FavoriteItem(
        entityId: widget.player.id,
        type: 'player',
        name: widget.player.fullName,
        imageUrl: widget.player.profilePicture,
        leagueId: widget.leagueId,
        leagueName: widget.leaugeName,
        starred: starred,
        notificationsEnabled: notif,
        createdAt: DateTime.now(),
        clubId: widget.clubData.id,
        clubName: widget.clubData.clubName,
        clubImageUrl: widget.clubData.clubProfileImg,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FavoriteItem?>(
      stream: _favService.watchEntity(widget.player.id),
      builder: (context, snap) {
        final fav = snap.data;
        final isStarred = fav?.starred ?? false;
        final isNotif = fav?.notificationsEnabled ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: PlayerDetailsAppBar(
            clubLogo: widget.clubData.clubProfileImg,
            leagueName: widget.leaugeName,
            clubName: widget.clubData.clubName,
            isStarred: isStarred,
            isNotificationEnabled: isNotif,
            onStar: () async {
              final err = await _favService.toggleStar(
                _buildFavoriteItem(starred: isStarred, notif: isNotif),
              );
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: Colors.red),
                );
              }
            },
            onNotification: () async {
              final err = await _favService.toggleNotification(
                _buildFavoriteItem(starred: isStarred, notif: isNotif),
              );
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: Colors.red),
                );
              }
            },
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, top: 32),
              child: Column(
                children: [
                  _buildPlayerHeader(),
                  const SizedBox(height: 16),
                  StatsCard(statsData: _stats, isLoading: _loading),
                  if (widget.player.clubHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildClubHistory(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerHeader() {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      color: AppColors.ternary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),

        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 12),
            Text(
              widget.player.fullName,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text(
              _formatDate(widget.player.dateOfBirth),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13,
                color: AppColors.ternaryGray,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trenutni klub:',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 14,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.clubData.clubProfileImg.isNotEmpty)
                              ClipOval(
                                child: Image.network(
                                  widget.clubData.clubProfileImg,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.clubData.clubName,
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sezona:',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 14,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              widget.player.season,
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),

                            const SizedBox(width: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prošli klubovi',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ...widget.player.clubHistory.map(_buildClubHistoryRow),
        ],
      ),
    );
  }

  Widget _buildClubHistoryRow(ClubHistoryEntry entry) {
    final logoUrl = _historyLogos[entry.clubId];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.sports_soccer,
                        size: 20,
                        color: AppColors.ternaryGray,
                      ),
                    )
                  : Icon(
                      Icons.sports_soccer,
                      size: 20,
                      color: AppColors.ternaryGray,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.clubName,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.player.profilePicture.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.player.profilePicture,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsAvatar(),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    final initials =
        '${widget.player.firstName.isNotEmpty ? widget.player.firstName[0] : ''}'
        '${widget.player.lastName.isNotEmpty ? widget.player.lastName[0] : ''}';
    return Container(
      width: 90,
      height: 90,
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
            fontSize: 28,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}.';
  }
}
