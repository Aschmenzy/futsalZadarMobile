import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class UtakmicaContainer extends StatelessWidget {
  const UtakmicaContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.85,
      height: screenHeight * 0.15,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Uzivo",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      color: Color.fromRGBO(26, 109, 175, 1),
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  Text(
                    "25:14",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      color: Color.fromRGBO(26, 109, 175, 1),
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        SizedBox(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          child: Image.asset(
                            "assets/images/clubLogo/hajduk.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Flexible(
                          child: Text(
                            "Hajduk",
                            style: TextStyle(
                              fontFamily: AppFonts.roboto.fontFamily,
                              color: Colors.black,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "2",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      color: Colors.black,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        SizedBox(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          child: Image.asset(
                            "assets/images/clubLogo/diamo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Flexible(
                          child: Text(
                            "Dinamo",
                            style: TextStyle(
                              fontFamily: AppFonts.roboto.fontFamily,
                              color: Colors.black,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "0",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      color: Colors.black,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
