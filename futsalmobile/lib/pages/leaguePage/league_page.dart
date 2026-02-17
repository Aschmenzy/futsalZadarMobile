import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_container.dart';

class LeaguePage extends StatelessWidget {
  const LeaguePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', scale: 0.7),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Futsal lige",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 2),

                  LeaugeContainer(
                    leaugeNum: 1,
                    leaugeName: 'Liga 1',
                    leaugeID: 'liga1',
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 2,
                    leaugeName: 'Liga 2',
                    leaugeID: 'liga2',
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 3,
                    leaugeName: 'Liga 3',
                    leaugeID: 'liga3',
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 4,
                    leaugeName: 'Liga 4',
                    leaugeID: 'liga4',
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
