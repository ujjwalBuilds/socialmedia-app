import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';

Future<List<dynamic>> fetchFriendRequests() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String userId = prefs.getString('user_id') ?? '';
  final String token = prefs.getString('user_token') ?? '';
  const String apiUrl = "${BASE_URL}api/followRequests?page=1&limit=10";

  final response = await http.get(
    Uri.parse(apiUrl),
    headers: {
      "userid": userId,
      "token": token,
    },
  );
  print("FRIEND DATA: ");
  print(response.body.toString());
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data["result"];
  } else {
    throw Exception("Failed to fetch friend requests");
  }
}

Future<List<dynamic>> fetchSentFriendRequests() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String userId = prefs.getString('user_id') ?? '';
  final String token = prefs.getString('user_token') ?? '';
  const String apiUrl = "${BASE_URL}api/sentRequests";

  final response = await http.get(
    Uri.parse(apiUrl),
    headers: {
      "userid": userId,
      "token": token,
    },
  );
  print("SENT FRIEND REQUESTS DATA: ");
  print(response.body.toString());
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data["result"] ?? [];
  } else {
    throw Exception("Failed to fetch sent friend requests");
  }
}

Future<bool> deleteSentRequest(String userId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String token = prefs.getString('user_token') ?? '';
  final String myUserId = prefs.getString('user_id') ?? '';
  final String apiUrl = "${BASE_URL}api/sentRequest/$userId";

  final response = await http.delete(
    Uri.parse(apiUrl),
    headers: {
      "userid": myUserId,
      "token": token,
    },
  );
  print("DELETE SENT REQUEST RESPONSE: ");
  print(response.body.toString());
  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception("Failed to delete sent request");
  }
}
