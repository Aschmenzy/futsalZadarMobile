import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class CalendarCard extends StatefulWidget {
  final DateTime currentDate;
  final ValueChanged<DateTime>? onDateChanged;

  const CalendarCard({
    super.key,
    required this.currentDate,
    this.onDateChanged,
  });

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.currentDate;
  }

  static const List<String> _dayNames = [
    'Nedjelja',
    'Ponedjeljak',
    'Utorak',
    'Srijeda',
    'Četvrtak',
    'Petak',
    'Subota',
  ];

  void _previousDay() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
      widget.onDateChanged?.call(_currentDate);
    });
  }

  void _nextDay() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 1));
      widget.onDateChanged?.call(_currentDate);
    });
  }

  String get _formattedDate {
    return '${_currentDate.day.toString().padLeft(2, '0')}'
        '.${_currentDate.month.toString().padLeft(2, '0')}'
        '.${_currentDate.year}';
  }

  String get _dayName => _dayNames[_currentDate.weekday % 7];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 0.5,
      child: Container(
        width: screenWidth,
        height: screenHeight * 0.05,
        decoration: BoxDecoration(
          color: AppColors.ternary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousDay,
              icon: const Icon(Icons.arrow_back_ios_sharp),
              color: AppColors.secondary,
            ),
            Row(
              children: [
                Text(_dayName, style: TextStyle(fontFamily: AppFonts.roboto)),
                const SizedBox(width: 6),
                Text(
                  _formattedDate,
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppFonts.roboto,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _nextDay,
              icon: const Icon(Icons.arrow_forward_ios_sharp),
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
