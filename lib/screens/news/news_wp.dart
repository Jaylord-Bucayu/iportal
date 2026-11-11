import 'package:flutter/material.dart';
import 'package:shop/models/news.dart';
import 'package:shop/screens/news/news_details_screen.dart';
import 'package:shop/screens/news/news_lists_screen.dart';
import 'package:shop/screens/news/news_service.dart';

import '../../../../constants.dart';


/// NewsWP: Displays a "Latest news" header and a horizontally scrollable
/// row of cards sourced live from the DSWD FO2 WordPress REST API
/// (https://fo2.dswd.gov.ph/wp-json/wp/v2/posts). Tapping a card opens
/// [NewsDetailScreen] with the full article. Tapping "View more" opens
/// [NewsListScreen] with the complete, scrollable list of posts.
class NewsWP extends StatefulWidget {
  const NewsWP({super.key});

  @override
  State<NewsWP> createState() => _NewsWPState();
}

class _NewsWPState extends State<NewsWP> {
  final NewsService _newsService = NewsService();
  late Future<List<NewsPost>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews(perPage: 10);
  }

  Future<void> _refresh() async {
    final future = _newsService.fetchNews(perPage: 10);
    setState(() => _newsFuture = future);
    await future;
  }

  void _openNewsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewsListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: newspaper icon + "Latest news" + "View more" ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.newspaper_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Latest news",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openNewsList,
                  child: const Text(
                    "View more",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: defaultPadding / 2),

          // ── Horizontal news card carousel ──
          SizedBox(
            height: 248,
            child: FutureBuilder<List<NewsPost>>(
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
                          const Icon(Icons.wifi_off_rounded,
                              color: Colors.black38),
                          const SizedBox(height: 6),
                          const Text(
                            "Couldn't load news.",
                            style: TextStyle(color: Colors.black54),
                          ),
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
                  return const Center(
                    child: Text(
                      "No news available.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding,
                  ),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return NewsCard(
                      post: post,
                      press: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NewsDetailScreen(post: post),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single news card: thumbnail on top, title + date below.
class NewsCard extends StatelessWidget {
  final NewsPost post;
  final VoidCallback press;

  const NewsCard({
    super.key,
    required this.post,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withOpacity(0.25),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.2,
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
          ],
        ),
      ),
    );
  }

}
/// Shared date formatter (e.g. "Aug 6, 2026") used by the card and detail
/// screen, without pulling in the `intl` package.
String formatNewsDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}