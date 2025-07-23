import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/pages/onboarding_screens/start_screen.dart';
import 'dart:convert';

import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;
  bool isshown = true; // For password visibility toggle

  Future<void> _showDeleteConfirmationDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Color(0xFF7400A5), width: 1.0),
          ),
          title: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF7400A5),
                size: 50.h,
              ),
              SizedBox(height: 12.h),
              Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Are You Sure You Want To Delete Your Account? This Action Cannot Be Undone',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'No',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirm delete
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Yes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // User confirmed, proceed with account deletion
      _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;
    final password = _passwordController.text.trim();

    if (userId == null || token == null || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user data or password.')),
      );
      return;
    }

    setState(() => _isDeleting = true);

    final url = Uri.parse('${BASE_URL}api/deleteAccount');

    try {
      final response = await http.post(
        url,
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        await userProvider.clearUserData(); // Clear shared prefs

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => StartScreen()), // Replace with your LoginScreen widget
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isDeleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Text('Delete Account', style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            
            Text(
              'Enter Your Password To Confirm Account Deletion',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 30.h),
            
            TextField(
              obscureText: isshown,
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: "Password",
                suffixIcon: InkWell(
                  onTap: () {
                    setState(() {
                      isshown = !isshown;
                    });
                  },
                  child: Icon(
                    Icons.remove_red_eye,
                    color: Color(0xFF7400A5),
                  )
                ),
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 16.sp,
                  color: isDarkMode ? AppColors.darkText : AppColors.lightText
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFF7400A5),
                    width: 1.25,
                  )
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFF7400A5),
                    width: 1.25,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFF7400A5),
                    width: 1.25,
                  ),
                )
              ),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            
            SizedBox(height: 40.h),
            
            SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _showDeleteConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7400A5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Color(0xFF7400A5).withOpacity(0.6),
                ),
                child: _isDeleting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Confirm Delete Account',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
