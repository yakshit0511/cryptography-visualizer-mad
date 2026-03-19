import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/post.dart';

/// Service for handling API requests
class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Fetch posts from JSONPlaceholder API
  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/posts'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Post.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}