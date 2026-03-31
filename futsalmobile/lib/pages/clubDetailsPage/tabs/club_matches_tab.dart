import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';

class ClubMatchesTab extends StatelessWidget {
  final ClubData clubData;

  const ClubMatchesTab({super.key, required this.clubData});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.6,
                    color: AppColors.ternaryGray,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
