import 'package:flutter/material.dart';

class SponsorsBanner extends StatelessWidget {
  const SponsorsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(color: Colors.black12),
      width: screenWidth * 0.85,
      height: screenHeight * 0.12,
    );
  }
}
