import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class NewsAppbar extends StatelessWidget implements PreferredSizeWidget {
  const NewsAppbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      automaticallyImplyLeading: false,

      flexibleSpace: SafeArea(
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.ternary,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),

              Text(
                "Natrag na vijesti",
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  color: AppColors.ternary,
                  fontSize: 17
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
