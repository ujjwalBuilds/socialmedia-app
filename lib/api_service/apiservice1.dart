import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';

class ApiService {


  late String token; // Will be initialized from SharedPreferences
  late String userId; // Will be initialized from SharedPreferences

  ApiService();

  /// Initialize `userId` and `token` from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('user_token') ?? '';
    userId = prefs.getString('user_id') ?? '';

    if (token.isEmpty || userId.isEmpty) {
      throw Exception('Token or userId not found in shared preferences');
    }
  }

  Future<dynamic> makeRequest({
    required String path,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    // Ensure token and userId are initialized
    if (token.isEmpty || userId.isEmpty) {
      throw Exception('Token or userId is not initialized');
    }

    final url = Uri.parse('${BASE_URL}$path');
    final headers = {
      'Content-Type': 'application/json',
      'token': token,
      'userid': userId,
    };

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API request failed: $e');
    }
  }
}
