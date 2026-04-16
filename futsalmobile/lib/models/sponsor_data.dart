class SponsorData {
  final String id;
  final String name;
  final String imageUrl;
  final String linkUrl;
  final bool isActive;
  final int order;

  const SponsorData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.linkUrl,
    required this.isActive,
    required this.order,
  });

  factory SponsorData.fromFirestore(Map<String, dynamic> map, String docId) {
    return SponsorData(
      id: docId,
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      linkUrl: map['linkUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? false,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'linkUrl': linkUrl,
    'isActive': isActive,
    'order': order,
  };

  factory SponsorData.fromJson(Map<String, dynamic> map) => SponsorData(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    imageUrl: map['imageUrl']?.toString() ?? '',
    linkUrl: map['linkUrl']?.toString() ?? '',
    isActive: map['isActive'] as bool? ?? false,
    order: (map['order'] as num?)?.toInt() ?? 0,
  );
}
