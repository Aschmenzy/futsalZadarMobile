import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/news/news_data.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/news_container.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';
import 'package:futsalmobile/widgets/utakmica_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.only( left: 32.0, right: 32.0, top: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
          
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', scale: 0.7),
                  ),
                  SizedBox(height: 20),
                  SponsorsBanner(),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      Text(
                        "Utakmice",
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          
                  SizedBox(height: 20),
                  UtakmicaContainer(),
                  SizedBox(height: 20),
                  UtakmicaContainer(),
                  SizedBox(height: 20),
                  UtakmicaContainer(),
                  SizedBox(height: 20),
                  UtakmicaContainer(),
                  SizedBox(height: 20),
          
                  SizedBox(height: screenHeight * 0.02),
                  //treba fetchati newsContainer ali samo onaj zadnji
                  Row(
                    children: [
                      Text(
                        "Najnovija vijest",
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          
                  SizedBox(height: screenHeight * 0.02),
          
                  FutureBuilder<NewsData?>(
                    future: _service.getLatestNews(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return SizedBox.shrink();
                      }
          
                      final news = snapshot.data!;
                      return NewsContainer(header: news.header, body: news.body);
                    },
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
