import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_data.dart';
import 'package:futsalmobile/pages/clubDetailsPage/widgets/teamLead_container.dart';
import 'package:futsalmobile/pages/clubDetailsPage/widgets/trainer_container.dart';
import 'package:futsalmobile/pages/playerDetailsPage/player_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class ClubTeamTab extends StatefulWidget {
  final ClubData clubData;
  final String leagueId;
  final String leaugeName;

  const ClubTeamTab({
    super.key,
    required this.clubData,
    required this.leagueId,
    required this.leaugeName,
  });

  @override
  State<ClubTeamTab> createState() => _ClubTeamTabState();
}

class _ClubTeamTabState extends State<ClubTeamTab> {
  final _service = FirebaseService();
  List<PlayerData> _players = [];
  bool _loading = true;
  String? _error;
  final Set<String> _favoritePlayers = {};

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      final players = await _service.getPlayersByClub(
        widget.leagueId,
        widget.clubData.id,
      );
      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greška pri učitavanju igrača: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  TrainerContainer(
                    screenHeight: screenHeight,
                    trainer: widget.clubData.trainer,
                  ),

                  const SizedBox(height: 10),

                  TeamleadContainer(
                    screenHeight: screenHeight,
                    teamLead: widget.clubData.teamLead,
                  ),

                  const SizedBox(height: 10),

                  _buildPlayersList(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );
    }

    if (_players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Nema upisanih igrača',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              color: AppColors.ternaryGray,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _players.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFF0F0F0),
          indent: 14,
          endIndent: 14,
        ),
        itemBuilder: (context, index) => _buildPlayerRow(_players[index]),
      ),
    );
  }

  Widget _buildPlayerRow(PlayerData player) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerDetailsPage(
            player: player,
            leaugeName: widget.leaugeName,
            leagueId: widget.leagueId,
            clubData: widget.clubData,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(player),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_favoritePlayers.contains(player.id)) {
                    _favoritePlayers.remove(player.id);
                  } else {
                    _favoritePlayers.add(player.id);
                  }
                });
              },
              child: Icon(
                _favoritePlayers.contains(player.id)
                    ? Icons.star
                    : Icons.star_border,
                color: _favoritePlayers.contains(player.id)
                    ? AppColors.secondary
                    : AppColors.ternaryGray,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(PlayerData player) {
    if (player.profilePicture.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          player.profilePicture,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsAvatar(player),
        ),
      );
    }
    return _initialsAvatar(player);
  }

  Widget _initialsAvatar(PlayerData player) {
    final initials =
        '${player.firstName.isNotEmpty ? player.firstName[0] : ''}'
        '${player.lastName.isNotEmpty ? player.lastName[0] : ''}';

    return Container(
      width: 42,
      height: 42,
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
            fontSize: 14,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
