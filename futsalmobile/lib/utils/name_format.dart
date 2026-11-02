/// Display form of a person's name as typed in the admin panel:
/// "LUKA BURCUL" -> "Luka Burcul", "dino  susak-vrhar" -> "Dino Susak-Vrhar".
/// Every word (and each part of a hyphenated or apostrophe name) starts with
/// a capital, the rest is lower case; extra whitespace is collapsed.
/// Use for people only — club names are left as the admin wrote them.
String formatPersonName(String? raw) {
  final name = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (name.isEmpty) return '';
  return name.toLowerCase().replaceAllMapped(
    RegExp(r"(^|[\s\-'’])(\S)"),
    (m) => '${m[1]}${m[2]!.toUpperCase()}',
  );
}

// Croatian alphabet order for the diacritic letters: C < Č < Ć < D < Đ < E,
// S < Š < T, Z < Ž. Each maps to its base letter plus a suffix above every
// other character, so code-unit comparison sorts it after all words that
// continue with the plain base letter ("Zoran" < "Žarko").
const _croatianSortKeys = {
  'č': 'c\uFFF0',
  'ć': 'c\uFFF1',
  'đ': 'd\uFFF0',
  'š': 's\uFFF0',
  'ž': 'z\uFFF0',
};

String _sortKey(String s) => s
    .toLowerCase()
    .split('')
    .map((ch) => _croatianSortKeys[ch] ?? ch)
    .join();

/// Case-insensitive name comparison in Croatian alphabetical order.
int compareNames(String a, String b) => _sortKey(a).compareTo(_sortKey(b));
