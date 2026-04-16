import 'news_data.dart';

class NewsPaginated {
  final List<NewsData> items;
  int offset;
  bool hasMore;

  NewsPaginated({
    this.items = const [],
    this.offset = 0,
    this.hasMore = true,
  });
}
