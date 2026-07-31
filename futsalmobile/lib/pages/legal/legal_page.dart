import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/main.dart';
import 'package:futsalmobile/pages/legal/legal_content.dart';
import 'package:futsalmobile/services/prefs_service.dart';

/// Shows the Terms of Service and Privacy Policy.
///
/// Two modes:
/// - [gateMode] = true — first-launch onboarding: the user reads each
///   document in turn and confirms it with a checkbox before continuing
///   (Terms of Service first, then Privacy Policy).
/// - [gateMode] = false — read-only tabbed viewer opened from the info
///   entry point on the home page.
class LegalPage extends StatefulWidget {
  final bool gateMode;
  const LegalPage({super.key, this.gateMode = false});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Gate flow state: step 0 = Terms of Service, step 1 = Privacy Policy.
  int _step = 0;
  bool _termsChecked = false;
  bool _privacyChecked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    await PrefsService.setLegalAccepted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.gateMode ? _buildGate() : _buildViewer();
  }

  // ── Onboarding gate ────────────────────────────────────────────────────────

  Widget _buildGate() {
    final isTermsStep = _step == 0;
    final checked = isTermsStep ? _termsChecked : _privacyChecked;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Image.asset('assets/images/logo.png', scale: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              isTermsStep ? 'Uvjeti korištenja' : 'Politika privatnosti',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Korak ${_step + 1} od 2',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12,
                color: AppColors.ternaryGray,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
                ),
                child: _LegalTextView(
                  text: isTermsStep ? kTermsOfServiceText : kPrivacyPolicyText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: checked,
                    onChanged: (v) => setState(() {
                      if (isTermsStep) {
                        _termsChecked = v ?? false;
                      } else {
                        _privacyChecked = v ?? false;
                      }
                    }),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.secondary,
                    title: Text(
                      isTermsStep
                          ? 'Pročitao/la sam i prihvaćam Uvjete korištenja'
                          : 'Pročitao/la sam i prihvaćam Politiku privatnosti',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (!isTermsStep) ...[
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(
                                    color: AppColors.secondary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => setState(() => _step = 0),
                              child: Text(
                                'Natrag',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.ternary,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: !checked
                                ? null
                                : isTermsStep
                                    ? () => setState(() => _step = 1)
                                    : _accept,
                            child: Text(
                              isTermsStep ? 'Dalje' : 'Prihvaćam i nastavi',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Read-only viewer ───────────────────────────────────────────────────────

  Widget _buildViewer() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.ternary),
        title: Text(
          'Pravne informacije',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            color: AppColors.ternary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentYellow,
          labelColor: AppColors.ternary,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Uvjeti korištenja'),
            Tab(text: 'Politika privatnosti'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LegalTextView(text: kTermsOfServiceText),
          _LegalTextView(text: kPrivacyPolicyText),
        ],
      ),
    );
  }
}

class _LegalTextView extends StatelessWidget {
  final String text;
  const _LegalTextView({required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 13.5,
          height: 1.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
