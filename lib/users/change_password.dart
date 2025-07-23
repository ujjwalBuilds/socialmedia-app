import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/users/change_newPassword.dart';
import 'dart:convert';
import 'package:socialmedia/utils/colors.dart';

import 'package:pinput/pinput.dart';
import 'package:socialmedia/utils/constants.dart';

class ChangePass extends StatefulWidget {
  @override
  _ChangePassState createState() => _ChangePassState();
}

class _ChangePassState extends State<ChangePass> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String _selectedCountryCode = "+1";
  bool otploadr = false;

  void _showCountryCodeDialog(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}";
        });
      },
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(16.0),
        inputDecoration: InputDecoration(
          hintText: "Search country...",
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    setState(() {
      otploadr = true;
    });

    print(_phone.text);
    print(_selectedCountryCode);
    print(_otpController.text);
    //print(_phone.text);

    final response = await http.post(
      Uri.parse("${BASE_URL}api/verify-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phoneNumber": _phone.text,
        "countryCode": _selectedCountryCode,
        "otp": _otpController.text,
        "forgot": "1"
      }),
    );

    if (response.statusCode == 200) {
      // Show success dialog instead of just a snackbar
      _showPasswordChangedDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text("Invalid OTP. Please try again." , style:  GoogleFonts.poppins(
            fontSize: 14.sp , fontWeight: FontWeight.bold
          ),))),
      );
    }

    setState(() {
      otploadr = false;
    });
  }

  // Add this method to show the success dialog
  void _showPasswordChangedDialog() {
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (context) => ResetPasswordScreen(
        phone: _phone.text, 
        countrycode: _selectedCountryCode,
      ))
    );
    return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: const Color(0xFF740085), width: 1.0),
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: const Color(0xFF740085),
                size: 60.sp,
              ),
              SizedBox(height: 12.h),
              Text(
                'Success!',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Your password was changed successfully',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontSize: 14.sp,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            SizedBox(
              width: 150.w,
              child: ElevatedButton(
                onPressed: () {
                  // Close dialog and navigate to the next screen
                  Navigator.of(context).pop(); // Close dialog
                  // Then navigate to the password reset screen
                  Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => ResetPasswordScreen(
                      phone: _phone.text, 
                      countrycode: _selectedCountryCode,
                    ))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF740085),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    print(_selectedCountryCode);
    print(_phone.text);

    final response = await http.post(
      Uri.parse("${BASE_URL}api/send-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phoneNumber": _phone.text,
        "countryCode": _selectedCountryCode,
        "forgot": "1"
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      log(responseBody.toString());
      setState(() {
        _isOtpSent = true;
      });
    } else {
      log("Failed to send OTP: ${response.statusCode}");
      log("Response body: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 16, 24, 43),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkGradient
                  : AppColors.lightGradient,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Text(
                    "Please Confirm Your Number",
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showCountryCodeDialog(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 15.5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Transparent background
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                          border: Border.all(
                            color: const Color(
                                0xFF740085), // Same border color as TextField
                            width: 1, // Border thickness
                          ),
                        ),
                        child: Text(
                          _selectedCountryCode,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors
                                    .black, // White in dark mode, black in light mode
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        decoration: InputDecoration(
                          hintText: "Enter Phone Number",
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          filled: true,
                          fillColor:
                              Colors.transparent, // Transparent background
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Rounded corners
                            borderSide: BorderSide(
                              color: const Color(
                                  0xFF740085), // Black border in light mode
                              width: 1, // Border thickness
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFF740085),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(
                                  0xFF740085), // Blue border when focused
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black, // Always black text
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                !_isOtpSent
                    ? Center(
                        child: ElevatedButton(
                          onPressed: _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7400A5),
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: _isLoading
                              ? LoadingAnimationWidget.inkDrop(
                                  color: Colors.white, size: 25)
                              : Text(
                                  'Send OTP',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )
                    : SizedBox(
                        height: 20.h,
                      ),
                if (_isOtpSent)
                  Pinput(
                    controller: _otpController,
                    length: 6,
                    closeKeyboardWhenCompleted: true,
                    defaultPinTheme: PinTheme(
                      width: 56,
                      height: 60,
                      textStyle: TextStyle(
                        fontSize: 25,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkText
                            : AppColors.lightText,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                _isOtpSent
                    ? Column(
                        children: [
                          SizedBox(
                            height: 40.h,
                          ),
                          Center(
                            child: ElevatedButton(
                                onPressed: _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                  0xFF740085),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 40),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: !otploadr
                                    ? Text(
                                        'Change Password',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      )
                                    : LoadingAnimationWidget.inkDrop(
                                        color: Colors.white, size: 25)),
                          ),
                        ],
                      )
                    : SizedBox(
                        height: 20.h,
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
