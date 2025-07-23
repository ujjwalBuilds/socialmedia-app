import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/pages/onboarding_screens/otp_screen.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OTPApiService {
  Future<void> sendOtp(String phoneNumber, String countryCode, BuildContext context, {String email=''}) async {
    const String url = '${BASE_URL}api/send-otp';

    try {
      final Map<String, String> payload = {
        "phoneNumber": phoneNumber,
        "countryCode": countryCode,
        "email": email,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String message = responseBody['message'] ?? "OTP Sent Successfully";
        final int otp = responseBody['otp'] ?? '';
        print(responseBody);
        print(message);

        // Show success message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Center(
        //       child: Text('$message- $otp' , style: GoogleFonts.poppins(
        //         color: Theme.of(context).brightness == Brightness.dark
        //                   ? Colors.black
        //                   : Colors.white,
        //             fontWeight: FontWeight.bold,
        //       ),
        //       ),
        //     ),
        //     behavior: SnackBarBehavior.floating,
        //     backgroundColor: Theme.of(context).brightness == Brightness.dark
        //                 ? Colors.white
        //                 : Colors.black,
        //     duration: const Duration(seconds: 20),
        //   ),
        // );

        // Navigate to the OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(number: phoneNumber, countrycode: countryCode, email: email)),
        );
      } else {
        final String errorMessage = jsonDecode(response.body)['message'] ?? "Failed to send OTP";

        // Show failure message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(errorMessage,
                style: TextStyle(color: Colors.white),
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text("Error: $e")),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      print("Error: $e");
    }
  }
}
