import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class LeadingTeams extends StatelessWidget {
  const LeadingTeams({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return  Container(
      width: double.infinity,
      height: screenHeight * 0.3,
      decoration: BoxDecoration(
        color: AppColors.ternary,
        borderRadius: BorderRadius.circular(10),
         boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            offset: Offset(0, 4),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],

      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vodeći timovi po ligama",
            style: TextStyle(
              fontFamily: AppFonts.roboto.fontFamily,
              fontWeight: FontWeight.w600
            ),),

            SizedBox(height: screenHeight * 0.015,),

            //tim jedan
            _teamRow(screenWidth: screenWidth),
            _teamRow(screenWidth: screenWidth),
            _teamRow(screenWidth: screenWidth),
            _teamRow(screenWidth: screenWidth),
          ],
        ),
      ),
    );
  }
}

class _teamRow extends StatelessWidget {
  const _teamRow({
    required this.screenWidth,
  });

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset("assets/images/clubLogo/dinamo.png"),
    
        SizedBox(width: screenWidth * 0.025,),
    
        //ime kluba i liga
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hajduk",
            style: TextStyle(
              fontFamily: AppFonts.roboto.fontFamily,
              color: AppColors.primary,
            ),
    
            ),
            Text("Liga 1.",
            style: TextStyle(
              fontFamily: AppFonts.roboto.fontFamily,
              color: AppColors.ternaryGray,
              fontSize: 12
            ),)
          ],
        ),
    
    
        SizedBox(width: screenWidth * 0.38,),
    
        //broj bodova i utakmica
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("67 bodova",
            style: TextStyle(
              fontFamily: AppFonts.roboto.fontFamily,
              color: AppColors.accent,
            ),

            
            ),
            Text("25 utakmica",
            style: TextStyle(
              fontFamily: AppFonts.roboto.fontFamily,
              color: AppColors.primary,
              fontSize: 12
            ),)
          ],
        ),
    
      ],
    );
  }
}