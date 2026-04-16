class NewsData {
  final String id;
  final String imageUrl;
  final DateTime createdAt;
  final String header;
  final String body;

  const NewsData({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.header,
    required this.body,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'createdAt': createdAt.toIso8601String(),
    'header': header,
    'body': body,
  };

  factory NewsData.fromJson(Map<String, dynamic> map) => NewsData(
    id: map['id']?.toString() ?? '',
    imageUrl: map['imageUrl']?.toString() ?? '',
    createdAt: map['createdAt'] != null ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()) : DateTime.now(),
    header: map['header']?.toString() ?? '',
    body: map['body']?.toString() ?? '',
  );

  factory NewsData.fromFirestore(Map<String, dynamic> map, String docId) {
    return NewsData(
      id: docId,
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      header: map['header'] ?? '',
      body: map['body'] ?? '',
    );
  }
}