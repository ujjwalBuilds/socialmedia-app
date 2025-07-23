import 'dart:convert'; // Needed for jsonEncode
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';

Future<void> rejectRequest(String otherId) async {
  const String apiUrl = "${BASE_URL}api/rejectRequest";
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String userId = prefs.getString('user_id') ?? '';
  final String token = prefs.getString('user_token') ?? '';

  try {
    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {
        "userid": userId,
        "token": token,
        "Content-Type": "application/json", // Ensure JSON content type
      },
      body: jsonEncode({
        "otherId": otherId, // Pass otherId as JSON
      }),
    );

    if (response.statusCode == 200) {
      print("Request rejected successfully");
      // Handle successful response
    } else {
      print("Failed to reject request: ${response.statusCode}");
      print("Response: ${response.body}");
      // Handle error response
    }
  } catch (e) {
    print("Error occurred: $e");
    // Handle network or other errors
  }
}
