class PlayoffGroupInfo {
  final String id;
  final String label;
  const PlayoffGroupInfo({required this.id, required this.label});
}

class PlayoffInfo {
  final bool hasLiga1;
  final List<PlayoffGroupInfo> ligaskaGroups;

  const PlayoffInfo({required this.hasLiga1, required this.ligaskaGroups});

  bool get hasAny => hasLiga1 || ligaskaGroups.isNotEmpty;
}

