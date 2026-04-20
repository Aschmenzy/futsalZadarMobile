class MatchMedia {
  final String url;
  final String storagePath;
  final DateTime uploadedAt;

  const MatchMedia({
    required this.url,
    required this.storagePath,
    required this.uploadedAt,
  });

  factory MatchMedia.fromJson(Map<String, dynamic> map) => MatchMedia(
    url: map['url']?.toString() ?? '',
    storagePath: map['storagePath']?.toString() ?? '',
    uploadedAt: map['uploadedAt'] != null
        ? DateTime.tryParse(map['uploadedAt'].toString()) ?? DateTime(1970)
        : DateTime(1970),
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'storagePath': storagePath,
    'uploadedAt': uploadedAt.toIso8601String(),
  };
}