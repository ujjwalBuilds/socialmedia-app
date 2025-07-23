import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/auth_apis/send_otp.dart';
import 'package:socialmedia/pages/onboarding_screens/login_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/privacyPolicyScreen.dart';
import 'package:socialmedia/pages/onboarding_screens/termsAndConditionsScreen.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:socialmedia/pages/onboarding_screens/otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController _phone = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = "+1"; // Default country code
  bool _isChecked = false;

  void _sendOtp() async {
    if (!_isChecked) {
      // Show Flutter toast message if checkbox is not checked
      Fluttertoast.showToast(msg: "Accept T&C and Privacy Policy Before Proceeding", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, timeInSecForIosWeb: 1, backgroundColor: Color(0xFF7400A5), textColor: Colors.white, fontSize: 13.0.sp);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await OTPApiService().sendOtp(_phone.text, _selectedCountryCode, context);
    } catch (e) {
      print("Error sending OTP: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCountryCodeDialog(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}"; // Update country code
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
        textStyle: TextStyle(
          fontSize: 16,
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
        ),
        searchTextStyle: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark ? AppColors.darkGradient : AppColors.lightGradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 130.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    "Let's Get Started",
                    style: GoogleFonts.montserrat(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 40.w),
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.montserrat(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(height: 28.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Container(
                    // decoration:
                    //     BoxDecoration(border: Border.all(color: Colors.white60)),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showCountryCodeDialog(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
                            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7400A5), width: 1.25)),
                            child: Text(
                              _selectedCountryCode,
                              style: GoogleFonts.montserrat(fontSize: 16.sp, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            decoration: InputDecoration(
                                hintText: "Enter Your Phone Number",
                                hintStyle: GoogleFonts.montserrat(fontSize: 16.sp, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF7400A5), // Black border in light mode
                                      width: 1.25, // Border thickness
                                    )),
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
                                    color: const Color(0xFF7400A5), // Blue border when focused
                                    width: 2,
                                  ),
                                )),
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _isChecked,
                          activeColor: Color(0xFF7400A5),
                          checkColor: Colors.white,
                          onChanged: (bool? value) {
                            setState(() {
                              _isChecked = value ?? false;
                            });
                          },
                        ),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.montserrat(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                            children: [
                              TextSpan(text: 'I agree to ', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText)),
                              TextSpan(
                                text: 'T&C',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()),
                                    );
                                  },
                              ),
                              TextSpan(text: ' and ', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText)),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Center(
                  child: Text(
                    'Already A Member?',
                    style: GoogleFonts.montserrat(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                  ),
                ),
                SizedBox(
                  height: 18.h,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 61.w),
                  child: Row(
                    children: [
                      // Left Gradient Line
                      Expanded(
                        child: Container(
                          height: 1.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: Theme.of(context).brightness == Brightness.dark
                                  ? [
                                      Colors.white, // Start transparent
                                      Colors.white24, // End light
                                    ]
                                  : [
                                      Colors.black, // Start transparent
                                      Colors.black54, // End light
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      // "or" Text
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                        },
                        child: Text(
                          '    Login',
                          style: GoogleFonts.montserrat(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        // child: Text(
                        //   "or",
                        //   style: TextStyle(
                        //     color: Colors.white70,
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ),
                      // Right Gradient Line
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: Theme.of(context).brightness == Brightness.dark
                                  ? [
                                      Colors.white, // Start transparent
                                      Colors.white24, // End light
                                    ]
                                  : [
                                      Colors.black, // Start transparent
                                      Colors.black54, // End light
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(350.w, 56.h),
                      backgroundColor: Color(0xFF7400A5),
                    ),
                    onPressed: () async {
                      final SharedPreferences prefs_number = await SharedPreferences.getInstance();
                      await prefs_number.setString('phone', _phone.text);
                      _sendOtp();
                    },
                    child: _isLoading
                        ? SimpleCircularProgressBar(
                            size: 20,
                            progressStrokeWidth: 4,
                            backStrokeWidth: 0,
                            progressColors: [
                              Colors.white,
                              Color(0xFF7400A5)
                            ],
                          )
                        : Text(
                            'Send OTP',
                            style: GoogleFonts.montserrat(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: 100.h,
                ),
                // Center(
                //   child: SvgPicture.asset(
                //     'assets/images/bondlogog.svg', // Use the SVG file path
                //     width: 150.w, // Adjust size as needed
                //     height: 150.h,
                //   ),
                // ),
                
                // Center(
                //   child: Text.rich(
                //     TextSpan(
                //       text: "BondBridge",
                //       style: GoogleFonts.leagueSpartan(
                //         fontSize: 25.sp, // Adjust based on your needs
                //         fontWeight: FontWeight.w800,
                //         foreground: Paint()
                //           ..shader = const LinearGradient(
                //             begin: Alignment.bottomLeft,
                //             end: Alignment.topRight,
                //             colors: [
                //               Color(0xFF3B01B7), // Dark purple (bottom left)
                //               Color(0xFF5E00FF), // Purple
                //               Color(0xFFBA19EB), // Pink-purple
                //               Color(0xFFDD0CC8), // Pink (top right)
                //             ],
                //             // stops: [1.0, 0.69, 0.34, 0.0]
                //           ).createShader(
                //             const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                //           ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
