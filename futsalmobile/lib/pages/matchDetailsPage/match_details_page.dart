import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/leaugePage/matchData/match_data.dart';
import 'package:futsalmobile/pages/matchDetailsPage/widgets/match_details_app_bar.dart';
import 'package:futsalmobile/pages/matchDetailsPage/widgets/match_events_widget.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class MatchDetailsPage extends StatefulWidget {
  final MatchData match;

  const MatchDetailsPage({super.key, required this.match});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  final _service = FirebaseService();
  late final Stream<MatchData> _matchStream;

  @override
  void initState() {
    super.initState();
    _matchStream = _service.watchMatch(widget.match);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MatchData>(
      stream: _matchStream,
      initialData: widget.match,
      builder: (context, snapshot) {
        final match = snapshot.data ?? widget.match;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MatchDetailsAppBar(match: match),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MatchEventsWidget(match: match),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
