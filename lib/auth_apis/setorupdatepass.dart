import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/pages/onboarding_screens/interests.dart';
import 'package:socialmedia/utils/constants.dart';

Future<void> setPassword(BuildContext context, String password, String userId , String token) async {
  final url = Uri.parse('${BASE_URL}api/set-password');
  final headers = {
    'Content-Type': 'application/json',
    'userId': userId, // Pass the userId directly as a header
    'token' : token
  };
  final body = jsonEncode({'password': password});

  try {
    final response = await http.put(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      print('Password updated successfully.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text('Password updated successfully!')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Interests(user_id: userId , token: token,),
        ),
      );
    } else {
      print('Failed to update password. Status Code: ${response.statusCode}');
      final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to update password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text(errorMessage)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (error) {
    print('An error occurred: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text('An error occurred. Please try again.')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
