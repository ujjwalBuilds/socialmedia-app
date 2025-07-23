import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:socialmedia/utils/colors.dart'; // Assuming this file contains AppColors

class ReferralCodeScreen extends StatelessWidget {
  final String referralCode;
  final int refferCount;
  final String baseUrl = 'https://www.bondbridge.online/signup?referral='; // Base URL for the referral link

  const ReferralCodeScreen({
    super.key,
    required this.referralCode,
    required this.refferCount,
  });

  // Function to copy the referral code to the clipboard
  void _copyCodeToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Function to copy the full referral link to the clipboard
  void _copyReferralLinkToClipboard(BuildContext context) {
    final fullLink = '$baseUrl$referralCode';
    Clipboard.setData(ClipboardData(text: fullLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Your Referral Code',
          style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 40.h),

            Text(
              'Share this code with your friends to invite them!',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 10.h),

            Text(
              '$refferCount Friends Joined',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20.h),

            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: const Color(0xFF7400A5),
                  width: 1.5.w,
                ),
              ),
              child: SelectableText(
                referralCode,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // Button to copy the referral code
            SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => _copyCodeToClipboard(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7400A5),
                  foregroundColor: Colors.white,
                  elevation: 0, // No shadow
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                ),
                child: Text(
                  'Copy Code',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h), // Added spacing between buttons

            // Button to copy the referral link
            SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => _copyReferralLinkToClipboard(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7400A5), // You can adjust the color if needed
                  foregroundColor: Colors.white,
                  elevation: 0, // No shadow
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                ),
                child: Text(
                  'Copy Referral Link',
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
