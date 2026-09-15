import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:url_launcher/url_launcher.dart';

const _androidPackageId = 'hr.futsalzadar.app';

/// Full-screen blocker shown when the installed build is below
/// `minBuildNumber` in config/app. There is no way past it except updating.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  Future<void> _openStore() async {
    // Play Store app first, browser as a fallback.
    final market = Uri.parse('market://details?id=$_androidPackageId');
    final web = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_androidPackageId',
    );
    try {
      if (await launchUrl(market, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 120, height: 120),
              const SizedBox(height: 32),
              Text(
                'Nova verzija je dostupna',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Za nastavak korištenja aplikacije potrebno je ažurirati '
                'aplikaciju na najnoviju verziju.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _openStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Ažuriraj',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
