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
  final Widget? clubLogo;
  final bool isStarred;

  const LeagueAppBar({
    super.key,
    required this.leagueName,
    required this.season,
    required this.tabController,
    this.onBack,
    this.onNotification,
    this.onStar,
    this.clubLogo,
    required this.seasons,
    this.onSeasonChanged,
    this.isStarred = false,
  });

  static String _formatSeason(String s) {
    final parts = s.split('-');
    if (parts.length == 2 && parts[0].length == 4 && parts[1].length == 4) {
      return '${parts[0].substring(2)}/${parts[1].substring(2)}';
    }
    return s;
  }

  String get _displaySeason => _formatSeason(season);

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
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      color: isStarred
                          ? AppColors.accentYellow
                          : AppColors.ternary,
                    ),
                    onPressed: onStar,
                    iconSize: 35,
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
                  clubLogo ??
                      Container(
                        width: 60,
                        height: 60,
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
                            fontFamily: AppFonts.roboto,
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
                                    _formatSeason(s),
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
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
                                _displaySeason,
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  color: AppColors.ternary,
                                  fontSize: 22,
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
          Tab(text: 'Statistika'),
        ],
      ),
    );
  }
}
