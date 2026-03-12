import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/pages/newsDetails/widgets/news_appBar.dart';
import 'package:intl/intl.dart';

class NewsDetailsPage extends StatelessWidget {
  final String header;
  final String body;
  final String? imageUrl;
  final DateTime date;
  const NewsDetailsPage({
    super.key,
    required this.header,
    required this.body,
    this.imageUrl,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final screenWith = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dateFormat = DateFormat('d.M.yyyy');
    return Scaffold(
      appBar: NewsAppbar(),
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Image.asset(
                        'assets/images/newsImage.png',
                        fit: BoxFit.fitWidth,
                      ),

                //datum kad je vijest objavljena
                Padding(
                  padding: EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          //iokna
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.secondary,
                            size: 28,
                          ),

                          SizedBox(width: screenWith * 0.02),

                          //formatirani datum
                          Text(
                            dateFormat.format(date),
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              color: AppColors.ternaryGray,
                            ),
                          ),
                        ],
                      ),

                      //naslov vijesti
                      SizedBox(height: screenHeight * 0.02),

                      Text(
                        header,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),

                      //divider
                      SizedBox(height: screenHeight * 0.02),
                      Divider(),

                      //tekst cijele vijesti
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        body,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
