import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection.dart';
import 'package:socialmedia/pages/onboarding_screens/login_screen.dart';
import 'package:socialmedia/utils/constants.dart';

Future<void> editProfile(
  BuildContext context, {
  required String name,
  required List<String> interests,
  required String address,
  required String userId,
  required String token,
  required String dob,
  required String bio,
  required String avatar,
  String? referralCode,
}) async {
  final url = Uri.parse('${BASE_URL}api/edit-profile');

  try {
    // Create a MultipartRequest
    final request = http.MultipartRequest('PUT', url)
      ..headers.addAll({
        'userId': userId,
        'token': token,
      });

    // Add fields to the request
    request.fields['name'] = name;
    request.fields['address'] = address;

    // Add interests as a JSON array string
    request.fields['interests'] = jsonEncode(interests);
    request.fields['dob'] = dob;
    request.fields['bio'] = bio;
    request.fields['avatar'] = avatar;

    if (referralCode != null) {
      request.fields['referralCode'] = referralCode.trim();
    }

    log(request.fields.toString());

    // Send the request
    final response = await request.send();

    // Handle the response
    if (response.statusCode == 200) {
      print('Profile updated successfully.');
      final responseBody = await response.stream.bytesToString();
      SharedPreferences _userloginstatus = await SharedPreferences.getInstance();
      _userloginstatus.setString('loginstatus', '2');

      print('this is the ${_userloginstatus.getString('loginstatus')}'); 
      
      print('Response: $responseBody');

      _userloginstatus.remove('referral');

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      print('Failed to update profile. Status Code: ${response.statusCode}');
      final responseBody = await response.stream.bytesToString();
      print('Error: $responseBody');
    }
  } catch (error) {
    print('An error occurred: $error');
  }
}
