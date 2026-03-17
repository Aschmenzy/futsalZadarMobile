import 'package:flutter/material.dart';

class SponsorsBanner extends StatelessWidget {
  const SponsorsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(color: Colors.black12),
      width: double.infinity,
      height: screenHeight * 0.12,
    );
  }
}
