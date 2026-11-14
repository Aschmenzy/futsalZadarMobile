import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

/// Liječnički status for the active season: green when the league has the
/// player's medical certificate, red when it doesn't. Voditelji check this
/// before putting a player on the match sheet.
class MedicalBadge extends StatelessWidget {
  final bool hasMedical;
  final double fontSize;

  const MedicalBadge({super.key, required this.hasMedical, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final color = hasMedical
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.6,
        vertical: fontSize * 0.25,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasMedical ? Icons.check_circle : Icons.cancel,
            size: fontSize + 2,
            color: color,
          ),
          SizedBox(width: fontSize * 0.35),
          Text(
            hasMedical ? 'Liječnički' : 'Nema liječnički',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
