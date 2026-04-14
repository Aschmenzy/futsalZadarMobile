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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: screenHeight * 0.2,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/newsImage.png',
                        width: double.infinity,
                        height: screenHeight * 0.2,
                        fit: BoxFit.cover,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
                child: Text(
                  header,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                child: Text(
                  body,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    color: Color.fromRGBO(167, 167, 167, 1),
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }
}
