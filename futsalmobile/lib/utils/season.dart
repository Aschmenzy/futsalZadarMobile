/// "2026/2027" and "2026-2027" are the same season.
String seasonKey(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

/// False when [season] is listed in [inactiveSeasons] (the admin marks
/// players and voditelji inactive per season, same ids as
/// `config/app.activeSeason`).
bool isActiveInSeason(List<String> inactiveSeasons, String? season) {
  if (season == null || season.isEmpty) return true;
  final key = seasonKey(season);
  return !inactiveSeasons.any((s) => seasonKey(s) == key);
}

/// "2026-2027" → "2026/2027" for display.
String formatSeason(String s) => s.replaceAll('-', '/');
