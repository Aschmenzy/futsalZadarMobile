import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class TeamleadContainer extends StatelessWidget {
  const TeamleadContainer({
    super.key,
    required this.screenHeight,
    required this.teamLead,
  });

  final double screenHeight;
  final String teamLead;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.08,
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(width: 10),

            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ternaryGray),
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/images/defProfile.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 5),
                Text(
                  "Voditelj",
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ternaryGray,
                    fontSize: 14,
                  ),
                ),
                Text(
                  teamLead.isEmpty ? "Voditelj nije upisan" : teamLead,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Spacer(flex: 3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
