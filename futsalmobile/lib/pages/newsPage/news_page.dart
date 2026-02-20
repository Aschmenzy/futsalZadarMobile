import 'package:flutter/material.dart';
import 'package:futsalmobile/constants/constants.dart';
import 'package:futsalmobile/models/news/news_data.dart';
import 'package:futsalmobile/pages/newsDetails/news_details_page.dart';
import 'package:futsalmobile/services/firebase_services.dart';
import 'package:futsalmobile/widgets/news_container.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _service = FirebaseService();
  List<NewsData> _news = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final news = await _service.getNews();
      setState(() {
        _news = news;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('NEWS ERROR: $e');
      setState(() {
        _error = 'Greska pri ucitavanju vijesti';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset('assets/images/logo.png', scale: 0.7),
                          ),
                          ..._news.map((item) => GestureDetector(
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
                                child: NewsContainer(header: item.header,
          body: item.body, imageUrl: item.imageUrl,),
                              )),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}