import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';

class DetailsTab extends StatelessWidget {
  const DetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background
          ),
          child: Column(
            children: [
              //baner za sponzora koji ce se povremeno pojavljivat
              SponsorsBanner(),
          
              SizedBox(height: screenHeight * 0.02),
              //postotak koliko je liga zavrsila do sad i koja je trenutna runa u prici
              Card(
                elevation: 0.5,
                child: Container(
                width: screenWidth * 0.85,
                height: screenHeight * 0.1,
                decoration: BoxDecoration(
                  color: AppColors.ternary,
                  borderRadius: BorderRadius.circular(15)
                ),
                ),
              ),
          
              SizedBox(height: screenHeight * 0.01),

              //kad je sljedeca utakmica i tko igra protiv koga
              Card(
                elevation: 0.5,
                child: Container(
                width: screenWidth * 0.85,
                height: screenHeight * 0.2,
                decoration: BoxDecoration(
                  color: AppColors.ternary,
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    
                  ],
                ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),
              //broj ekipa u ligi
          
            Card(
                elevation: 0.5,
                child: Container(
                width: screenWidth * 0.85,
                height: screenHeight * 0.08,
                decoration: BoxDecoration(
                  color: AppColors.ternary,
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Broj ekipa",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      color: AppColors.ternaryGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                    ),
                    Text("11",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700
                    ) 
                    )
                  ],
                ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),
          
              //niza liga/visa liga ako je ima

              Card(
                elevation: 0.5,
                child: Container(
                width: screenWidth * 0.85,
                height: screenHeight * 0.09,
                decoration: BoxDecoration(
                  color: AppColors.ternary,
                 borderRadius: BorderRadius.circular(15)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Niža liga",
                      style: TextStyle(
                        fontFamily: AppFonts.roboto.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600
                      ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          //slika
                          Image.asset('assets/images/logo.png',scale: 2,),

                          SizedBox(width: screenWidth * 0.02,),

                          //liga
                          Text("3. Futsal liga Zadar", style: 
                          TextStyle(
                            fontFamily: AppFonts.roboto.fontFamily,

                          ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),
            ],
          ),
        ),
      ),
    );
  }
}