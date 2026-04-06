import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/club_data.dart';

class ClubTableTab extends StatelessWidget {
  final ClubData clubData;

  const ClubTableTab({super.key, required this.clubData});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: ColoredBox(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 32, right: 32),
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
