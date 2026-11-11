/// Model representing a single WordPress "post" returned by the
/// DSWD FO2 REST API: https://fo2.dswd.gov.ph/wp-json/wp/v2/posts
class NewsPost {
  final int id;
  final String title;
  final String excerpt;
  final String content; // raw HTML, use stripHtml() before showing as plain text
  final String imageUrl;
  final DateTime date;
  final String link;

  NewsPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.imageUrl,
    required this.date,
    required this.link,
  });

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    return NewsPost(
      id: json['id'] ?? 0,
      title: stripHtml(json['title']?['rendered'] ?? ''),
      excerpt: stripHtml(json['excerpt']?['rendered'] ?? ''),
      content: json['content']?['rendered'] ?? '',
      imageUrl: _extractImageUrl(json),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      link: json['link'] ?? '',
    );
  }

  /// The sample response doesn't embed media objects, but it does carry
  /// the featured image inside `yoast_head_json.og_image`. We fall back
  /// to an empty string (handled by the UI with a placeholder) if that's
  /// missing too.
  static String _extractImageUrl(Map<String, dynamic> json) {
    try {
      final ogImage = json['yoast_head_json']?['og_image'];
      if (ogImage is List && ogImage.isNotEmpty) {
        final url = ogImage.first['url'];
        if (url is String && url.isNotEmpty) return url;
      }
    } catch (_) {
      // ignore malformed payloads, fall through to empty string
    }
    return '';
  }

  /// Strips HTML tags and decodes the handful of entities WordPress
  /// commonly emits (curly quotes, nbsp, ampersand, hashtags, etc.).
  static String stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll('&#8216;', '\u2018')
        .replaceAll('&#8220;', '\u201C')
        .replaceAll('&#8221;', '\u201D')
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8212;', '\u2014')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}