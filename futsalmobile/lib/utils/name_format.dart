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
