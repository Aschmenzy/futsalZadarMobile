import 'dart:async';
import 'package:flutter/material.dart';
import 'package:futsalmobile/models/sponsor_data.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:url_launcher/url_launcher.dart';

class SponsorsBanner extends StatefulWidget {
  const SponsorsBanner({super.key});

  @override
  State<SponsorsBanner> createState() => _SponsorsBannerState();
}

class _SponsorsBannerState extends State<SponsorsBanner> {
  final _service = FirebaseService();

  List<SponsorData> _sponsors = [];
  int _index = 0;
  Timer? _timer;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sponsors = await _service.getSponsors();
      if (!mounted) return;
      setState(() {
        _sponsors = sponsors;
        _loaded = true;
      });
      if (sponsors.length > 1) {
        _timer = Timer.periodic(const Duration(seconds: 10), (_) {
          if (!mounted) return;
          setState(() => _index = (_index + 1) % _sponsors.length);
        });
      }
    } catch (e) {
      debugPrint('[SponsorsBanner] failed to load sponsors: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _sponsors.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;

    final sponsor = _sponsors[_index];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: GestureDetector(
        key: ValueKey(_index),
        onTap: () async {
          final uri = Uri.tryParse(sponsor.linkUrl);
          if (uri == null) return;
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint(
              '[SponsorsBanner] could not launch ${sponsor.linkUrl}: $e',
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            sponsor.imageUrl,
            width: double.infinity,
            height: screenHeight * 0.12,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
