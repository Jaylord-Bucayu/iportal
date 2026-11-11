import 'package:flutter/material.dart';
import 'package:shop/models/news.dart';
import 'package:shop/screens/news/news_details_screen.dart';
import 'package:shop/screens/news/news_service.dart';
import 'package:shop/screens/news/news_wp.dart' show formatNewsDate;

import '../../../../constants.dart';

/// NewsListScreen: Full, vertically-scrollable list of all news posts,
/// opened from the "View more" button on the home [NewsWP] section.
/// Supports pull-to-refresh.
class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final NewsService _newsService = NewsService();
  late Future<List<NewsPost>> _newsFuture;

  // Bump this if you want to load more posts per page from the API.
  static const int _perPage = 30;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews(perPage: _perPage);
  }

  Future<void> _refresh() async {
    final future = _newsService.fetchNews(perPage: _perPage);
    setState(() => _newsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Latest news",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: FutureBuilder<List<NewsPost>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.black38),
                    const SizedBox(height: 6),
                    const Text(
                      "Couldn't load news.",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text("Try again"),
                    ),
                  ],
                ),
              ),
            );
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      "No news available.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              addRepaintBoundaries: false,
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding,
              ),
              itemCount: posts.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _NewsListTile(
                  post: post,
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(post: post),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A full-width row tile used in [NewsListScreen]: thumbnail on the left,
/// title + date on the right.
class _NewsListTile extends StatelessWidget {
  final NewsPost post;
  final VoidCallback press;

  const _NewsListTile({
    required this.post,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: press,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.25),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: post.imageUrl.isNotEmpty
                      ? Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(color: Colors.grey[300]);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.newspaper_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: Color(0xFF171733),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatNewsDate(post.date),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        )
    );
    }
}