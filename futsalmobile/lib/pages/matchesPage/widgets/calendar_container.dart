import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';

class CalendarCard extends StatefulWidget {
  final DateTime currentDate;
  final ValueChanged<DateTime>? onDateChanged;

  /// Days that have at least one match, normalized to year/month/day.
  /// Drives the dot indicator under a day cell.
  final Set<DateTime> matchDays;

  const CalendarCard({
    super.key,
    required this.currentDate,
    this.onDateChanged,
    this.matchDays = const {},
  });

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime _currentDate;

  /// First day of the month shown in the expanded grid.
  late DateTime _visibleMonth;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.currentDate;
    _visibleMonth = DateTime(_currentDate.year, _currentDate.month);
  }

  @override
  void didUpdateWidget(covariant CalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(widget.currentDate, oldWidget.currentDate)) {
      _currentDate = widget.currentDate;
      _visibleMonth = DateTime(_currentDate.year, _currentDate.month);
    }
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

  static const List<String> _monthNames = [
    'Siječanj',
    'Veljača',
    'Ožujak',
    'Travanj',
    'Svibanj',
    'Lipanj',
    'Srpanj',
    'Kolovoz',
    'Rujan',
    'Listopad',
    'Studeni',
    'Prosinac',
  ];

  /// Monday-first weekday initials.
  static const List<String> _weekdayLabels = ['P', 'U', 'S', 'Č', 'P', 'S', 'N'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _selectDate(DateTime date) {
    setState(() {
      _currentDate = date;
      _visibleMonth = DateTime(date.year, date.month);
    });
    widget.onDateChanged?.call(date);
  }

  void _previous() {
    if (_expanded) {
      setState(() {
        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      });
    } else {
      _selectDate(_currentDate.subtract(const Duration(days: 1)));
    }
  }

  void _next() {
    if (_expanded) {
      setState(() {
        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      });
    } else {
      _selectDate(_currentDate.add(const Duration(days: 1)));
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _visibleMonth = DateTime(_currentDate.year, _currentDate.month);
      }
    });
  }

  String get _formattedDate {
    return '${_currentDate.day.toString().padLeft(2, '0')}'
        '.${_currentDate.month.toString().padLeft(2, '0')}'
        '.${_currentDate.year}';
  }

  String get _dayName => _dayNames[_currentDate.weekday % 7];

  String get _monthLabel =>
      '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 0.5,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          width: screenWidth,
          decoration: BoxDecoration(
            color: AppColors.ternary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: screenHeight * 0.05,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back_ios_sharp),
                      color: AppColors.secondary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleExpanded,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _expanded ? _monthLabel : _dayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: AppFonts.roboto),
                              ),
                            ),
                            if (!_expanded) ...[
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
                            Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward_ios_sharp),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
              if (_expanded) _buildMonthGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // weekday: Mon = 1 ... Sun = 7 -> leading blanks in a Monday-first grid.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final rows = ((leadingBlanks + daysInMonth) / 7).ceil();

    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: _weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ternaryGray,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          for (int row = 0; row < rows; row++)
            Row(
              children: List.generate(7, (col) {
                final dayNumber = row * 7 + col - leadingBlanks + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 36));
                }
                final date = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  dayNumber,
                );
                return Expanded(
                  child: _buildDayCell(
                    date,
                    isSelected: _isSameDay(date, _currentDate),
                    isToday: _isSameDay(date, today),
                    hasMatch: widget.matchDays.contains(date),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date, {
    required bool isSelected,
    required bool isToday,
    required bool hasMatch,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _selectDate(date);
        setState(() => _expanded = false);
      },
      child: SizedBox(
        height: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.secondary : Colors.transparent,
                border: !isSelected && isToday
                    ? Border.all(color: AppColors.secondary, width: 1)
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 12,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppColors.ternary : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasMatch ? AppColors.accent : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
