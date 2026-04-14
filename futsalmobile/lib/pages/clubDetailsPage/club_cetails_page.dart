import 'package:flutter/material.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/favorite_item.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_details_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_matches_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_team_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_table_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/widgets/clubs_details_appBar.dart';
import 'package:futsalmobile/services/favorites_service.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class ClubCetailsPage extends StatefulWidget {
  final String clubId;
  final String clubName;
  final String leagueId;
  final String clubLogo;
  final String leagueName;
  final String season;

  const ClubCetailsPage({
    super.key,
    required this.clubId,
    required this.clubName,
    required this.clubLogo,
    required this.leagueName,
    required this.leagueId,
    required this.season,
  });

  @override
  State<ClubCetailsPage> createState() => _ClubCetailsPageState();
}

class _ClubCetailsPageState extends State<ClubCetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _service = FirebaseService();
  final _favService = FavoritesService();

  ClubData? _clubData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClub();
  }

  Future<void> _loadClub() async {
    final data = await _service.getClubById(widget.leagueId, widget.clubId);
    if (!mounted) return;
    setState(() {
      _clubData = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  FavoriteItem _buildFavoriteItem({bool starred = false, bool notif = false}) =>
      FavoriteItem(
        entityId: widget.clubId,
        type: 'club',
        name: widget.clubName,
        imageUrl: widget.clubLogo,
        leagueId: widget.leagueId,
        leagueName: widget.leagueName,
        starred: starred,
        notificationsEnabled: notif,
        createdAt: DateTime.now(),
        season: widget.season,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FavoriteItem?>(
      stream: _favService.watchEntity(widget.clubId),
      builder: (context, snap) {
        final fav = snap.data;
        final isStarred = fav?.starred ?? false;
        final isNotif = fav?.notificationsEnabled ?? false;

        final appBar = ClubDetailsAppBar(
          tabController: _tabController,
          leagueName: widget.leagueName,
          clubName: widget.clubName,
          clubLogo: widget.clubLogo,
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
        );

        if (_loading) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_clubData == null) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: Text('Greška pri učitavanju kluba')),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: TabBarView(
            controller: _tabController,
            children: [
              ClubDetailsTab(clubData: _clubData!, leagueId: widget.leagueId),
              ClubMatchesTab(
                clubData: _clubData!,
                leagueId: widget.leagueId,
                season: widget.season,
              ),
              ClubTableTab(
                clubData: _clubData!,
                leagueId: widget.leagueId,
                leagueName: widget.leagueName,
                season: widget.season,
              ),
              ClubTeamTab(
                clubData: _clubData!,
                leagueId: widget.leagueId,
                leaugeName: widget.leagueName,
              ),
            ],
          ),
        );
      },
    );
  }
}
