import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class PlayerDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String clubLogo;
  final String leagueName;
  final String clubName;
  final VoidCallback? onBack;
  final VoidCallback? onNotification;
  final VoidCallback? onStar;

  const PlayerDetailsAppBar({
    super.key,
    required this.clubLogo,
    required this.leagueName,
    required this.clubName,
    this.onBack,
    this.onNotification,
    this.onStar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 90);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Column(
          children: [
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
                    'Natrag na lige',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      color: AppColors.ternary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onNotification,
                    icon: const Icon(
                      Icons.notifications_none,
                      size: 32,
                      color: AppColors.ternary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.star_border,
                      size: 32,
                      color: AppColors.ternary,
                    ),
                    onPressed: onStar,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 4, 32, 20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: clubLogo.isNotEmpty
                          ? Image.network(clubLogo, fit: BoxFit.cover)
                          : const Icon(Icons.sports_soccer, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          clubName,
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
    );
  }
}
