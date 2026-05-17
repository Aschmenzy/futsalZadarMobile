import 'package:flutter/material.dart';
import 'package:futsalmobile/models/playoff_tie.dart';
import 'package:futsalmobile/pages/playoffPage/widgets/bracket_widget.dart';

class BracketTab extends StatelessWidget {
  final List<PlayoffTie> ties;
  const BracketTab({super.key, required this.ties});

  @override
  Widget build(BuildContext context) => BracketWidget(ties: ties);
}
