import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:socialmedia/utils/constants.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = "+1";
  final TextEditingController _phone = TextEditingController();
  // Boolean variables to toggle password visibility
  bool _isOldPasswordHidden = true;
  bool _isNewPasswordHidden = true;

  Future<void> _changePassword() async {
    String oldPassword = _oldPasswordController.text;
    String newPassword = _newPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fields cannot be empty")),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("New password must be at least 6 characters long")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Access UserProviderall
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final String? token = userProvider.userToken;
    final String? userId = userProvider.userId;

    final response = await http.post(
      Uri.parse("${BASE_URL}api/reset-password"),
      headers: {
        "Content-Type": "application/json",
        "token": token!,
        "userid": userId ?? "",
      },
      body: jsonEncode({
        "phoneNumber": _phone.text,
        "countryCode": _selectedCountryCode,
        "password": newPassword,
        "oldPassword": oldPassword,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
      Navigator.pop(context); // Go back
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong")),
      );
      print(response.body); // Debug log
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark ? AppColors.darkGradient : AppColors.lightGradient,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50.h,
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.black,
                  ),
                ),
                SizedBox(
                  height: 20.h,
                ),
                Text(
                  "Change Password",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                SizedBox(height: 20),

                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showCountryCodeDialog(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15.5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Transparent background
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                          border: Border.all(
                            color: const Color(0xFF740085), // Same border color as TextField
                            width: 1, // Border thickness
                          ),
                        ),
                        child: Text(
                          _selectedCountryCode,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // White in dark mode, black in light mode
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        decoration: InputDecoration(
                          hintText: "Enter Phone Number",
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          filled: true,
                          fillColor: Colors.transparent, // Transparent background
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                            borderSide: BorderSide(
                              color: const Color(0xFF740085), // Black border in light mode
                              width: 1, // Border thickness
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFF7400A5),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFF740085), // Blue border when focused
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // Always black text
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Old Password Field
                TextField(
                  controller: _oldPasswordController,
                  obscureText: _isOldPasswordHidden,
                  decoration: InputDecoration(
                    hintText: "Old Password",
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: Color(0xFF7400A5), // Change border color
                        width: 2, // Border thickness
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isOldPasswordHidden ? Icons.visibility_off : Icons.visibility,
                        color: Color(0xFF7400A5),
                      ),
                      onPressed: () {
                        setState(() {
                          _isOldPasswordHidden = !_isOldPasswordHidden;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: const Color(0xFF740085), // Border color when not focused
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: const Color(0xFF740085), // Border color when the field is focused
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // New Password Field
                TextField(
                  controller: _newPasswordController,
                  obscureText: _isNewPasswordHidden,
                  decoration: InputDecoration(
                    hintText: "New Password",
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: Color(0xFF7400A5), // Change border color
                        width: 2, // Border thickness
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordHidden ? Icons.visibility_off : Icons.visibility,
                        color: Color(0xFF7400A5),
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordHidden = !_isNewPasswordHidden;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: const Color(0xFF740085), // Border color when not focused
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: const Color(0xFF740085), // Border color when the field is focused
                        width: 2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // Change Password Button
                Center(
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading
                          ? LoadingAnimationWidget.inkDrop(color: Colors.white, size: 25)
                          : Text(
                              'Change Password',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
