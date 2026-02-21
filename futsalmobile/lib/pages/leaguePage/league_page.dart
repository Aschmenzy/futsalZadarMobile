import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leading_teams.dart';
import 'package:futsalmobile/pages/leaguePage/widgets/leauge_container.dart';
import 'package:futsalmobile/services/firebase_services.dart';

class LeaguePage extends StatefulWidget {
  const LeaguePage({super.key});

  @override
  State<LeaguePage> createState() => _LeaguePageState();
}

class _LeaguePageState extends State<LeaguePage> {
  final _service = FirebaseService();
  final Map<String, int> _clubCounts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    for (final id in ['liga1', 'liga2', 'liga3', 'liga4']) {
      final count = await _service.getClubCount(id);
      setState(() => _clubCounts[id] = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', scale: 0.7),
                  ),
                  SizedBox(height: 40),

                  SizedBox(height: 2),

                  LeaugeContainer(
                    leaugeNum: 1,
                    leaugeName: 'Liga 1',
                    leaugeID: 'liga1',
                    numOfClubs: _clubCounts["liga1"],
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 2,
                    leaugeName: 'Liga 2',
                    leaugeID: 'liga2',
                    numOfClubs: _clubCounts["liga2"],
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 3,
                    leaugeName: 'Liga 3',
                    leaugeID: 'liga3',
                    numOfClubs: _clubCounts["liga3"],
                  ),

                  SizedBox(height: 20),

                  LeaugeContainer(
                    leaugeNum: 4,
                    leaugeName: 'Liga 4',
                    leaugeID: 'liga4',
                    numOfClubs: _clubCounts["liga4"],
                  ),

                  SizedBox(height: 20),

                  //vodeci timpovi po ligama PLACE HOLDER
                  LeadingTeams()

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
