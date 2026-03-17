import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class NewsContainer extends StatelessWidget {
  final String header;
  final String body;
  final String? imageUrl;

  const NewsContainer({
    super.key,
    required this.header,
    required this.body,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        Container(
          width: double.infinity,
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
                imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Image.asset('assets/images/newsImage.png', scale: 0.7),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    header,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
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
                      body,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
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
        ),
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }
}
