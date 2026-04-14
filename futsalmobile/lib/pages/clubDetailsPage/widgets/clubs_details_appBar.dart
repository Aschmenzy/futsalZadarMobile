import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class ClubDetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String leagueName;
  final String? clubName;
  final TabController tabController;
  final VoidCallback? onBack;
  final VoidCallback? onNotification;
  final VoidCallback? onStar;
  final String? clubLogo;
  final bool isStarred;
  final bool isNotificationEnabled;

  const ClubDetailsAppBar({
    super.key,
    required this.leagueName,
    required this.tabController,
    this.onBack,
    this.onNotification,
    this.onStar,
    this.clubLogo,
    this.clubName,
    this.isStarred = false,
    this.isNotificationEnabled = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 120);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Column(
          children: [
            //tipka natrag na lige
            Container(
              height: kToolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.ternary,
                      size: 20,
                    ),
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                  ),
                  Text(
                    "Natrag na lige",
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      color: AppColors.ternary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onNotification,
                    icon: Icon(
                      isNotificationEnabled
                          ? Icons.notifications
                          : Icons.notifications_none,
                      size: 32,
                      color: isNotificationEnabled
                          ? AppColors.accentYellow
                          : AppColors.ternary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      size: 32,
                      color: isStarred
                          ? AppColors.accentYellow
                          : AppColors.ternary,
                    ),
                    onPressed: onStar,
                  ),
                ],
              ),
            ),
            // Podatci o ligi
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 20),
              child: Row(
                children: [
                  // Logo lige
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(clubLogo!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // League Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          leagueName,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clubName!,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: TabBar(
        controller: tabController,
        indicatorColor: const Color(0xFFE91E63),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Detalji'),
          Tab(text: 'Utakmice'),
          Tab(text: 'Tablica'),
          Tab(text: 'Ekipa'),
        ],
      ),
    );
  }
}
