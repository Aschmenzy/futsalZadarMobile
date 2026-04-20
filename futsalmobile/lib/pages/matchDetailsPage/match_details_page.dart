import 'dart:async';

import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_media.dart';
import 'package:futsalmobile/pages/matchDetailsPage/widgets/match_details_app_bar.dart';
import 'package:futsalmobile/pages/matchDetailsPage/widgets/match_events_widget.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/sponsors_banner.dart';
import 'package:futsalmobile/widgets/standings_card.dart';

class MatchDetailsPage extends StatefulWidget {
  final MatchData match;

  const MatchDetailsPage({super.key, required this.match});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage>
    with TickerProviderStateMixin {
  final _service = FirebaseService();

  late MatchData _match;
  late TabController _tabController;
  List<MatchMedia> _media = [];
  bool _loading = true;
  Stream<MatchData>? _liveStream;
  StreamSubscription? _invalidationSub;

  bool get _hasPhotos => _media.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _media = widget.match.media;
    _tabController = TabController(
      length: _media.isNotEmpty ? 3 : 2,
      vsync: this,
    );
    _fetchMatchDetail();
    _invalidationSub = _service.onCacheInvalidated.listen(
      (_) => _fetchMatchDetail(),
    );
  }

  Future<void> _fetchMatchDetail() async {
    try {
      final fresh = await _service.getMatchDetail(widget.match.matchId);
      if (!mounted) return;

      setState(() {
        _match = fresh;
        if (fresh.media.isNotEmpty) _media = fresh.media;

        if ((fresh.isLive || fresh.status == 'paused') && _liveStream == null) {
          _liveStream = _service.watchMatch(fresh);
        }
        if (_media.isNotEmpty && _tabController.length == 2) {
          _tabController.dispose();
          _tabController = TabController(length: 3, vsync: this);
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invalidationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_liveStream != null) {
      return StreamBuilder<MatchData>(
        stream: _liveStream!,
        initialData: _match,
        builder: (context, snapshot) => _buildPage(snapshot.data ?? _match),
      );
    }
    return _buildPage(_match);
  }

  Widget _buildPage(MatchData match) {
    final tabs = ['Detalji', 'Tablica', if (_hasPhotos) 'Fotografije'];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MatchDetailsAppBar(
            match: match,
            tabController: _tabController,
            tabLabels: tabs,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _detailsTab(match),
                _standingsTab(match),
                if (_hasPhotos) _photosTab(match),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsTab(MatchData match) {
    // The detail HTTP endpoint strips matchState (internal field).
    // For events, prefer the live stream data or widget.match from the bulk fetch,
    // both of which include matchState.
    final eventsMatch = match.matchState != null ? match : widget.match;
    return SingleChildScrollView(
      child: Column(
        children: [
          MatchEventsWidget(match: eventsMatch),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _standingsTab(MatchData match) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SponsorsBanner(),
            const SizedBox(height: 16),
            StandingsCard(
              leagueCode: match.leagueCode,
              leagueName: match.league,
              leaugeSeason: match.season,
              highlightedTeamNames: {match.homeTeam, match.awayTeam},
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _photosTab(MatchData match) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _media.length,
      itemBuilder: (context, index) {
        final photo = _media[index];
        return GestureDetector(
          onTap: () => _openFullscreen(context, _media, index),
          child: Image.network(
            photo.url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.background,
              child: const Icon(
                Icons.broken_image,
                color: AppColors.ternaryGray,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFullscreen(
    BuildContext context,
    List<MatchMedia> photos,
    int initial,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FullscreenGallery(photos: photos, initialIndex: initial),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<MatchMedia> photos;
  final int initialIndex;

  const _FullscreenGallery({required this.photos, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_current + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.photos[index].url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
