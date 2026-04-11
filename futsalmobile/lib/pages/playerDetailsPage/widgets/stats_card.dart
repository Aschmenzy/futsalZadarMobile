import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/playerData/player_stats_data.dart';

class StatsCard extends StatefulWidget {
  final PlayerStatsData? statsData;
  final bool isLoading;
  const StatsCard({
    super.key,
    required this.statsData,
    required this.isLoading,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.scoreboard_outlined,
                color: AppColors.secondary,
                size: 25,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistika ove sezone',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                _buildStatBox(
                  value: widget.statsData?.totalGoals.toInt().toString() ?? '0',
                  label: 'Golova',
                  color: const Color(0xFF4ECDC4),
                ),
                const SizedBox(width: 12),
                _buildStatBox(
                  value:
                      widget.statsData?.matchesPlayed.toInt().toString() ?? '0',
                  label: 'Utakmica',
                  color: const Color(0xFFFAD65E),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.ternary, height: 1),
            const SizedBox(height: 12),
            _buildCardRow(
              label: 'Žuti kartoni',
              value: widget.statsData?.yellowCards.toInt() ?? 0,
            ),
            const SizedBox(height: 8),
            _buildCardRow(
              label: 'Crveni kartoni',
              value: widget.statsData?.redCards.toInt() ?? 0,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

Widget _buildStatBox({
  required String value,
  required String label,
  required Color color,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCardRow({required String label, required int value}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 14,
          color: AppColors.primary,
        ),
      ),
      Text(
        value.toString(),
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    ],
  );
}
