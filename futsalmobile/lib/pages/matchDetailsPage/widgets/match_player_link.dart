import 'package:flutter/material.dart';
import 'package:futsalmobile/models/club_data.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_data.dart';
import 'package:futsalmobile/pages/playerDetailsPage/player_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';

/// Opens the profile of a player tapped on the match detail page.
///
/// Match documents only carry a player id and the team name, so the full
/// player and club records are resolved from the cached league data first.
/// The club whose name matches the team is tried first; if the player is not
/// on it (renamed club, mid-season transfer) the rest of the league is scanned.
class MatchPlayerLink {
  MatchPlayerLink._();

  static bool _opening = false;

  static String _nameKey(String name) => name.trim().toLowerCase();

  static Future<void> open(
    BuildContext context, {
    required String leagueId,
    required String leagueName,
    required String teamName,
    required String playerId,
  }) async {
    if (_opening || playerId.isEmpty || leagueId.isEmpty) return;
    _opening = true;

    final service = FirebaseService();
    ClubData? club;
    PlayerData? player;

    try {
      final clubs = await service.getClubsByLeague(leagueId);
      club = clubs
          .where((c) => _nameKey(c.clubName) == _nameKey(teamName))
          .firstOrNull;

      if (club != null) {
        final players = await service.getPlayersByClub(leagueId, club.id);
        player = players.where((p) => p.id == playerId).firstOrNull;
      }

      if (player == null) {
        for (final c in clubs) {
          if (c.id == club?.id) continue;
          final players = await service.getPlayersByClub(leagueId, c.id);
          final found = players.where((p) => p.id == playerId).firstOrNull;
          if (found != null) {
            player = found;
            club = c;
            break;
          }
        }
      }
    } catch (_) {}

    _opening = false;
    if (!context.mounted) return;

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
          leaugeName: leagueName,
        ),
      ),
    );
  }
}
