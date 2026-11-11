import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/news.dart';



/// Talks to the DSWD Field Office 2 WordPress REST API.
class NewsService {
  static const String _baseUrl =
      'https://fo2.dswd.gov.ph/wp-json/wp/v2/posts';

  /// GET /wp-json/wp/v2/posts
  /// [page] and [perPage] map straight to WP's `page` / `per_page` params.
  /// [category] is optional (WP category id, e.g. 17 for "4ps" in the sample).
  Future<List<NewsPost>> fetchNews({
    int page = 1,
    int perPage = 10,
    int? category,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      // Trim the payload to only what NewsPost needs.
      '_fields':
      'id,date,title,excerpt,content,link,yoast_head_json',
      if (category != null) 'categories': '$category',
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: query);

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => NewsPost.fromJson(item))
          .toList();
    }

    throw Exception(
      'Failed to load news (status ${response.statusCode})',
    );
  }

  /// GET /wp-json/wp/v2/posts/{id}
  /// Useful if you navigate to the detail screen with only an id
  /// (e.g. from a deep link) instead of a full [NewsPost].
  Future<NewsPost> fetchNewsById(int id) async {
    final uri = Uri.parse('$_baseUrl/$id').replace(queryParameters: {
      '_fields': 'id,date,title,excerpt,content,link,yoast_head_json',
    });

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
      json.decode(utf8.decode(response.bodyBytes));
      return NewsPost.fromJson(data);
    }

    throw Exception(
      'Failed to load news item (status ${response.statusCode})',
    );
  }
}