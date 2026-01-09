import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/widgets/news_container.dart';
import 'package:futsalmobile/widgets/utakmica_container.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('assets/images/logo.png', scale: 0.7),
                ),

                SizedBox(height: 20),

                NewsContainer(),
                SizedBox(height: 20),
                UtakmicaContainer(),
                SizedBox(height: 20),
                UtakmicaContainer(),
                SizedBox(height: 20),
                UtakmicaContainer(),
                SizedBox(height: 20),
                UtakmicaContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
