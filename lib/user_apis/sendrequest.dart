import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';

Future<void> sendRequest(String userId, String token, String sentToId) async {
  const String url = '${BASE_URL}api/sendRequest';

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'userid': userId,
        'token': token,
        'Content-Type': 'application/json', // Ensure JSON content type
      },
      body: jsonEncode({
        'sentTo': sentToId, // Encode the body as JSON
      }),
    );

    if (response.statusCode == 200) {
      // Handle success response
      print('Request sent successfully: ${response.body}');
    } else {
      // Handle error response
      print('Failed to send request. Status code: ${response.statusCode}');
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Error sending request: $e');
  }
}
