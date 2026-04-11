import 'package:flutter/material.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_details_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_matches_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_team_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/tabs/club_table_tab.dart';
import 'package:futsalmobile/pages/clubDetailsPage/widgets/clubs_details_appBar.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: ClubDetailsAppBar(
          tabController: _tabController,
          leagueName: widget.leagueName,
          clubName: widget.clubName,
          clubLogo: widget.clubLogo,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_clubData == null) {
      return Scaffold(
        appBar: ClubDetailsAppBar(
          tabController: _tabController,
          leagueName: widget.leagueName,
          clubName: widget.clubName,
          clubLogo: widget.clubLogo,
        ),
        body: Center(child: Text('Greška pri učitavanju kluba')),
      );
    }

    return Scaffold(
      appBar: ClubDetailsAppBar(
        tabController: _tabController,
        leagueName: widget.leagueName,
        clubName: widget.clubName,
        clubLogo: widget.clubLogo,
      ),
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
  }
}
