import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/pages/onboarding_screens/interests.dart';
import 'package:socialmedia/pages/onboarding_screens/login_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/user_input_fields.dart';
import 'package:socialmedia/utils/constants.dart';

Future<void> verifyOtp(String phoneNumber, String countryCode, String otp ,BuildContext context) async {
  const String url = '${BASE_URL}api/verify-otp';

  try {
    // Create the request payload
    final Map<String, String> payload = {
      "phoneNumber": phoneNumber,
      "countryCode": countryCode,
      "otp": otp,
    };

    // Make the POST request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    // Handle the response
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final String userid = responseBody['userDetails']['_id'];
      final String token = responseBody['token'];
      print("OTP verified successfully: ${responseBody['message']}");
      final String message = responseBody['message'] ?? "OTP verified successfully";
      SharedPreferences _userloginstatus = await SharedPreferences.getInstance();
      _userloginstatus.setString('loginstatus', '1'); 
      _userloginstatus.setString('temp_userid', userid);
      _userloginstatus.setString('temp_token', token);
      print('this is your login status $_userloginstatus');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text(message,style: TextStyle(color: Colors.white),)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF7400A5),
            duration: const Duration(seconds: 1),
          ),
        );
        print(' ye le bhai');
        print(userid);
        Navigator.push(context, MaterialPageRoute(builder: (context)=> UserInputFields(userid: userid,token: token,)));
    } else {
      final errorMessage = jsonDecode(response.body)['message'] ?? "Failed to verify OTP";
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(errorMessage,
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                        ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      print("Failed to verify OTP: $errorMessage");
    }
  } catch (e) {
    print("Error: $e");
  }
}