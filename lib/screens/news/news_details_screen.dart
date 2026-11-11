import 'package:flutter/material.dart';
import 'package:shop/models/news.dart';

import '../../../../constants.dart';
import 'news_wp.dart' show formatNewsDate;

/// Full-article view for a single [NewsPost]. Reached by tapping a
/// [NewsCard] in [NewsWP].
class NewsDetailScreen extends StatelessWidget {
  final NewsPost post;

  const NewsDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Open original article',
                onPressed: () {
                  // Hook this up to url_launcher if you want it to open
                  // post.link in a browser / share sheet.
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: post.imageUrl.isNotEmpty
                  ? Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[300]),
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.newspaper_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Color(0xFF171733),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.black45),
                      const SizedBox(width: 6),
                      Text(
                        formatNewsDate(post.date),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Article body. NewsPost.content is raw WP HTML; here we
                  // render it as plain text via stripHtml(). Swap this
                  // Text widget for a flutter_html Html(data: post.content)
                  // widget if you want real HTML rendering (headings,
                  // links, embedded images, etc.).
                  Text(
                    NewsPost.stripHtml(post.content),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}