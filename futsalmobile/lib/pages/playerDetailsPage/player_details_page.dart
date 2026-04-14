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

  @override
  void initState() {
    super.initState();
    _loadStats();
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
