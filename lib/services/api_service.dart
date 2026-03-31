import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/post.dart';
import '../models/cipher_info.dart';

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

  /// Fetch cipher algorithms information from local API data
  /// Returns a list of cryptographic cipher algorithms with detailed information
  Future<List<CipherInfo>> fetchCiphers() async {
    try {
      // Using local cipher database - returns cryptographic cipher algorithms
      // This provides detailed information about cryptographic ciphers
      final ciphersData = [
        {
          'id': 1,
          'name': 'Caesar Cipher',
          'type': 'Substitution',
          'description': 'One of the simplest and most famous cipher techniques. Each letter is shifted by a fixed number of positions in the alphabet.',
          'algorithm': 'Character rotation by fixed key value (1-25)',
          'complexity': 'O(n) | Very Low Security',
          'keyRequirements': ['Numeric key (1-25)', 'Defines shift amount']
        },
        {
          'id': 2,
          'name': 'Playfair Cipher',
          'type': 'Polygraphic Substitution',
          'description': 'A manual symmetric encryption technique that encrypts pairs of letters (digraphs) using a 5x5 letter grid.',
          'algorithm': 'Digraph encryption using 5x5 key matrix with 3 rules for pair positioning',
          'complexity': 'O(n) | Low Security (Vulnerable to frequency analysis)',
          'keyRequirements': ['String key (min 5 chars)', 'Generates 5x5 grid matrix']
        },
        {
          'id': 3,
          'name': 'Hill Cipher',
          'type': 'Polygraphic Substitution',
          'description': 'A polygraphic substitution cipher based on linear algebra. Encrypts blocks of letters as a whole using matrix multiplication.',
          'algorithm': 'Block encryption using matrix multiplication and modular arithmetic (mod 26)',
          'complexity': 'O(n*k²) | Medium Security (requires matrix inversion)',
          'keyRequirements': ['2x2 or 3x3 matrix', 'Determinant must be coprime to 26']
        },
        {
          'id': 4,
          'name': 'Vigenère Cipher',
          'type': 'Polyalphabetic Substitution',
          'description': 'An extension of the Caesar cipher where each character uses a different shift value based on the repeating key.',
          'algorithm': 'Multiple Caesar shifts based on repeating key character positions',
          'complexity': 'O(n) | Medium Security (vulnerable to frequency analysis attacks)',
          'keyRequirements': ['Alphabetic key', 'Repeats for message length']
        },
        {
          'id': 5,
          'name': 'Substitution Cipher',
          'type': 'Monoalphabetic Substitution',
          'description': 'Each letter is replaced with another letter based on a substitution key. Creates a one-to-one mapping.',
          'algorithm': 'Character-to-character substitution using custom mapping table',
          'complexity': 'O(n) | Low Security (vulnerable to frequency analysis)',
          'keyRequirements': ['Key must contain unique letters', 'All 26 letters should be included']
        },
        {
          'id': 6,
          'name': 'Atbash Cipher',
          'type': 'Substitution',
          'description': 'A substitution cipher where each letter is replaced by its reverse in the alphabet (A↔Z, B↔Y, etc).',
          'algorithm': 'Reverse alphabet mapping: position maps to (25 - position)',
          'complexity': 'O(n) | Very Low Security (symmetric and reversible)',
          'keyRequirements': ['No key required', 'Fixed reverse mapping']
        },
      ];

      return ciphersData
          .map((item) => CipherInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error loading cipher data: $e');
    }
  }
}