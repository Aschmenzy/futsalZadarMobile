import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class NewsContainer extends StatelessWidget {
  const NewsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenWidth * 0.85,
      height: screenHeight * 0.2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/newsImage.png', scale: 0.7),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                "Pobjeda hrvatske reprezentacije!!!!!",
                style: TextStyle(
                  fontFamily: AppFonts.roboto.fontFamily,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
                softWrap: true,
                overflow: TextOverflow.fade,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla dignissim eros non commodo venenatis. Donec tempor odio sed purus cursus lobortis ut vel turpis.Class aptent taciti sociosqu ad litora torquent per conubia nostraa torquent per conubia nostra...Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla dignissim eros non commodo venenatis. Donec tempor odio sed",
                  style: TextStyle(
                    fontFamily: AppFonts.roboto.fontFamily,
                    color: Color.fromRGBO(167, 167, 167, 1),
                  ),
                  softWrap: true,
                  overflow: TextOverflow.fade,
                  maxLines: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
