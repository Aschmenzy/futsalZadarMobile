import 'package:cloud_firestore/cloud_firestore.dart';
import 'news_data.dart';

class NewsPaginated {
  final List<NewsData> items;
  DocumentSnapshot? lastDocument;
  bool hasMore;

  NewsPaginated({
    this.items = const [],
    this.lastDocument,
    this.hasMore = true,
  });
}