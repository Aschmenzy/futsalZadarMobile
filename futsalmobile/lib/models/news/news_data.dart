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