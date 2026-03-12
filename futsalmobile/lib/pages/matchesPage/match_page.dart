import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';

class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', scale: 0.7),
                  ),

                  SizedBox(height: screenHeight * 0.035),

                  //kalendar bar ------------- PLACEHOLDER
                  Card(
                    elevation: 1,
                    child: Container(
                      width: screenWidth * 0.85,
                      height: screenHeight * 0.05,
                      decoration: BoxDecoration(
                        color: AppColors.ternary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.arrow_back_ios_sharp),
                            color: AppColors.secondary,
                          ),

                          Row(children: [Text("Utorak "), Text("03.01.2025")]),

                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.arrow_forward_ios_sharp),
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.035),

                  SponsorsBanner(),

                  SizedBox(height: screenHeight * 0.035),

                  Text(
                    "Utakmice",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
