import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/news/news_paginated.dart';
import 'package:futsalmobile/pages/newsDetails/news_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/news_container.dart';
import 'package:futsalmobile/widgets/shimmer_loading.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _service = FirebaseService();
  final NewsPaginated _paginated = NewsPaginated(items: []);
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _paginated.hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getNewsPaginated(
        limit: 5,
        lastDocument: _paginated.lastDocument,
      );
      setState(() {
        _paginated.items.addAll(result.items);
        _paginated.lastDocument = result.lastDocument;
        _paginated.hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Greska pri ucitavanju vijesti';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: _paginated.items.isEmpty && _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null && _paginated.items.isEmpty
              ? Center(child: Text(_error!))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      _paginated.items.length +
                      (_paginated.hasMore ? 1 : 0) +
                      1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/logo.png',
                              scale: 0.7,
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.02),
                        ],
                      );
                    }
                    final newsIndex = index - 1;
                    if (newsIndex >= _paginated.items.length) {
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: ShimmerLoading(
                            width: screenWidth * 0.85,
                            height: screenHeight * 0.2,
                          ),
                        ),
                      );
                    }
                    final item = _paginated.items[newsIndex];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsDetailsPage(
                            header: item.header,
                            body: item.body,
                            imageUrl: item.imageUrl,
                            date: item.createdAt,
                          ),
                        ),
                      ),
                      child: NewsContainer(
                        header: item.header,
                        body: item.body,
                        imageUrl: item.imageUrl,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
