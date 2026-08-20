import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/tournament/tournament_data.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/pro_badge.dart';

/// Lists tournament teams; expanding a team lazily loads its players
/// (with PRO badges for professionals).
class TournamentTeamsTab extends StatefulWidget {
  final String tournamentId;

  const TournamentTeamsTab({super.key, required this.tournamentId});

  @override
  State<TournamentTeamsTab> createState() => _TournamentTeamsTabState();
}

class _TournamentTeamsTabState extends State<TournamentTeamsTab> {
  final _service = FirebaseService();
  List<TournamentTeam> _teams = [];
  final Map<String, Future<List<TournamentPlayer>>> _playerFutures = {};
  bool _loading = true;
  String? _error;
  StreamSubscription? _invalidationSub;

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _invalidationSub = _service.onTournamentsInvalidated.listen((_) {
      if (!mounted) return;
      // Drop the memoized player futures too — the roster cache was just
      // cleared, so keeping them would pin the pre-update squads on screen.
      _playerFutures.clear();
      _loadTeams();
    });
  }

  @override
  void dispose() {
    _invalidationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _service.getTournamentTeams(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Greška pri učitavanju momčadi: $e';
        _loading = false;
      });
    }
  }

  Future<List<TournamentPlayer>> _playersFor(String teamId) {
    return _playerFutures.putIfAbsent(
      teamId,
      () => _service.getTournamentTeamPlayers(widget.tournamentId, teamId),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      );
    }
    if (_teams.isEmpty) {
      return Center(
        child: Text(
          'Nema upisanih momčadi',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            color: AppColors.ternaryGray,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildTeamCard(_teams[index]),
    );
  }

  Widget _buildTeamCard(TournamentTeam team) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _teamLogo(team),
          title: Text(
            team.name,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          children: [
            FutureBuilder<List<TournamentPlayer>>(
              future: _playersFor(team.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Greška pri učitavanju igrača',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  );
                }
                final players = snap.data ?? [];
                if (players.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nema upisanih igrača',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        color: AppColors.ternaryGray,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                    for (final p in players)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: AppColors.ternaryGray,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontSize: 13.5,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.isProfessional) ...[
                              const SizedBox(width: 6),
                              const ProBadge(),
                            ],
                            const Spacer(),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamLogo(TournamentTeam team) {
    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: team.logo.isNotEmpty
            ? Image.network(
                team.logo,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _logoPlaceholder(),
              )
            : _logoPlaceholder(),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.sports, size: 18, color: Colors.grey.shade400),
    );
  }
}
