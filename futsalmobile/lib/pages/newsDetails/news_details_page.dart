import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/pages/newsDetails/widgets/news_appBar.dart';

class NewsDetailsPage extends StatelessWidget {
  const NewsDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWith = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: NewsAppbar(),
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,

              children: [
                Image.asset("assets/images/newsBanner.png", fit: BoxFit.cover),

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
                            "24.studeni 2025.",
                            style: TextStyle(
                              fontFamily: AppFonts.roboto.fontFamily,
                              color: AppColors.ternaryGray,
                            ),
                          ),
                        ],
                      ),

                      //naslov vijesti
                      SizedBox(height: screenHeight * 0.02),

                      Text(
                        "Poraz hrvatske reprezentacije",
                        style: TextStyle(
                          fontFamily: AppFonts.roboto.fontFamily,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),

                      //tko je napisao vijest
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset("assets/images/clubLogo/hajduk.png"),

                          SizedBox(width: screenWith * 0.02),

                          Text(
                            "Marko Kovačević",
                            style: TextStyle(
                              fontFamily: AppFonts.roboto.fontFamily,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      //divider
                      SizedBox(height: screenHeight * 0.02),
                      Divider(),

                      //tekst cijele vijesti
                      //tekst cijele vijesti
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Hrvatska nogometna reprezentacija doživjela je poraz u susretu koji je od samog početka nosio ogroman pritisak i visoka očekivanja. Unatoč borbenosti i nekoliko obećavajućih trenutaka, ključne prilike ostale su neiskorištene, a protivnik je znao kazniti svaku pogrešku.\n\nPrvo poluvrijeme donijelo je izjednačenu igru, ali Hrvatska je teško pronalazila ritam u završnici. Nekoliko opasnih situacija pred protivničkim golom ostalo je bez realizacije, što se pokazalo presudnim. U nastavku susreta protivnik je iskoristio trenutak nepažnje i stigao do vodstva koje je promijenilo tijek utakmice.\n\nPokušaji Hrvatske da se vrati u igru bili su energični, no nedovoljno konkretni. Završni pritisak nije donio pogodak, a frustracija se mogla osjetiti i na terenu i na tribinama.\n\nPoraz predstavlja korak unazad u borbi za plasman, ali ostavlja i jasnu poruku: pred reprezentacijom je posao koji zahtijeva više koncentracije, bolju realizaciju i povratak prepoznatljivoj čvrstini.",
                        style: TextStyle(
                          fontFamily: AppFonts.roboto.fontFamily,
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
