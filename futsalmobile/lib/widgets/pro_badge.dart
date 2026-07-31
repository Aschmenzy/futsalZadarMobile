import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

/// Small "PRO" tag shown next to professional players' names.
/// Mirrors the isProfessional flag set in the admin panel.
class ProBadge extends StatelessWidget {
  final double fontSize;
  const ProBadge({super.key, this.fontSize = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.6,
        vertical: fontSize * 0.25,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentYellow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.black,
        ),
      ),
    );
  }
}
