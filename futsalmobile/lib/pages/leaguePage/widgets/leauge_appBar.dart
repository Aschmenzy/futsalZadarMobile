import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class LeagueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String leagueName;
  final String season;
  final List<String> seasons;
  final TabController tabController;
  final VoidCallback? onBack;
  final VoidCallback? onNotification;
  final VoidCallback? onStar;
  final ValueChanged<String>? onSeasonChanged;
  final Widget? leagueLogo;

  const LeagueAppBar({
    super.key,
    required this.leagueName,
    required this.season,
    required this.tabController,
    this.onBack,
    this.onNotification,
    this.onStar,
    this.leagueLogo,
    required this.seasons,
    this.onSeasonChanged,
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
                      fontFamily: AppFonts.roboto.fontFamily,
                      color: AppColors.ternary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.star_border,
                      color: AppColors.ternary,
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
                  leagueLogo ??
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo_withBg.png',
                            fit: BoxFit.cover,
                          ),
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
                            fontFamily: AppFonts.roboto.fontFamily,
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        PopupMenuButton<String>(
                          onSelected: onSeasonChanged,
                          enabled: seasons.isNotEmpty,
                          padding: EdgeInsets.zero,
                          color: AppColors.secondary,
                          itemBuilder: (context) => seasons
                              .map(
                                (s) => PopupMenuItem<String>(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto.fontFamily,
                                      color: Colors.white,
                                      fontWeight: s == season
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                season,
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto.fontFamily,
                                  color: AppColors.ternary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.ternary,
                                size: 24,
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
          fontFamily: AppFonts.roboto.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppFonts.roboto.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Detalji'),
          Tab(text: 'Utakmice'),
          Tab(text: 'Tablica'),
          Tab(text: 'Statistika'),
        ],
      ),
    );
  }
}
