import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class LeagueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String leagueName;
  final String season;
  final TabController tabController;
  final VoidCallback? onBack;
  final VoidCallback? onNotification;
  final VoidCallback? onStar;
  final VoidCallback? onSeasonTap;
  final Widget? leagueLogo;

  const LeagueAppBar({
    super.key,
    required this.leagueName,
    required this.season,
    required this.tabController,
    this.onBack,
    this.onNotification,
    this.onStar,
    this.onSeasonTap,
    this.leagueLogo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
          Text("Natrag na lige", style: TextStyle(color: AppColors.ternary)),
        ],
      ),
      leadingWidth: 40,
      title: Row(
        children: [
          leagueLogo ??
              Center(child: Image.asset('assets/images/logo_withBg.png')),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                leagueName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onSeasonTap,
                child: Row(
                  children: [
                    Text(
                      season,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: onNotification,
        ),
        IconButton(
          icon: const Icon(Icons.star_border, color: Colors.white),
          onPressed: onStar,
        ),
      ],
      bottom: TabBar(
        controller: tabController,
        indicatorColor: const Color(0xFFE91E63),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
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
