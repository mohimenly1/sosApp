import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String? urlToImage;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
    );
  }
}

class NewsService {
  static const String _apiKey = 'd05598891998454a875b92ccf1c1e63b';

  static const String _baseUrl = 'https://newsapi.org/v2/everything';

  Future<List<NewsArticle>> fetchNews() async {
    final url = '$_baseUrl?q=tripoli?&apiKey=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> articlesJson = data['articles'];
        // Filter out articles that might have been removed
        final validArticles =
            articlesJson.where((json) => json['title'] != "[Removed]").toList();
        return validArticles.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        // Provide more specific error from the API if available
        final errorData = json.decode(response.body);
        throw Exception('Failed to load news: ${errorData['message']}');
      }
    } catch (e) {
      throw Exception(
          'Failed to connect to the news service. Please check your internet connection.');
    }
  }
}
