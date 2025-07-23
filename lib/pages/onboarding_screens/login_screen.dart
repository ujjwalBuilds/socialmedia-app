import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:socialmedia/auth_apis/login.dart';
import 'package:socialmedia/pages/onboarding_screens/signup_screen.dart';
import 'package:socialmedia/users/change_password.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _phone = TextEditingController();
  TextEditingController _pass = TextEditingController();
  String _selectedCountryCode = "+1";

  bool isshown = true;

  bool _isLoading = false; // To manage the loading state

  void _loginuser() async {
    setState(() {
      _isLoading = true; // Show the loader
    });

    try {
      await loginUser(context, _phone.text, _selectedCountryCode, _pass.text);
    } catch (e) {
      // Handle any error that might occur
      print("Error sending OTP: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide the loader
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
      textStyle: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
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
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkGradient
                      : AppColors.lightGradient),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 130.h,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Text(
                      "Let's Get Started",
                      style: GoogleFonts.montserrat(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText),
                    ),
                  ),
                  SizedBox(height: 10.h,),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Text(
                      "Login...",
                      style: GoogleFonts.montserrat(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText),
                    ),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Container(
                    // decoration:
                    //     BoxDecoration(border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                    //       ? Colors.white60
                    //       : Colors.grey.shade600,)),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showCountryCodeDialog(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 15.5.h, horizontal: 10.w),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                               border: Border.all(
                                color: const Color(0xFF7400A5),
                                width: 1.25
                              )
                               
                            ),
                            child: Text(
                              _selectedCountryCode,
                              style: GoogleFonts.montserrat(
                                  fontSize: 16.sp, color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.lightText,
                  ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            decoration: InputDecoration(
                              hintText: "Enter Your Phone",
                              hintStyle: GoogleFonts.montserrat(
                                  fontSize: 16.sp,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                      color: const Color(0xFF7400A5), // Black border in light mode
                                      width: 1.25, // Border thickness
                                    )
                              ),
                              enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF7400A5),
                                      width: 1.25,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF7400A5), // Blue border when focused
                                      width: 1.25,
                                    ),
                                  )
                            ),
                            style:  TextStyle(color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.lightText,
                  ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  SizedBox(
                    height: 18.h,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Container(
                      // decoration: BoxDecoration(
                      //     border: Border.all(color: Colors.white60)),
                      child: TextField(
                        obscureText: isshown,
                        controller: _pass,
                        decoration: InputDecoration(
                          //prefixIcon: const Icon(Icons.phone, color: Colors.white),
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
                              )),
                  
                          hintStyle: GoogleFonts.montserrat(
                              fontSize: 16.sp,
                              color:
                                  Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkText
                                      : AppColors.lightText),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Color(0xFF7400A5), // Change border color
                                width: 1.25, // Border thickness
                              )
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF7400A5), // Border color when not focused
                                width: 1.25,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF7400A5), // Border color when the field is focused
                                width: 1.25,
                              ),
                            )
                        ),
                        style:  TextStyle(color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.lightText,
                  ),
                        //keyboardType: TextInputType.phone,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h,),
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> ChangePass()));
                      },
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text('Forgot Password' , style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline
                        ),),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 18.h,
                  ),
                  Center(
                    child: Text(
                      'New Here?',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText),
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
                            height: 1,
                            decoration:  BoxDecoration(
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
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignupScreen()));
                          },
                          child: Text(
                            '  Signup',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                                fontSize: 20.sp,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText),
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
                            decoration:  BoxDecoration(
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
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size(350.w, 56.h),
                            backgroundColor: Color(0xFF7400A5),),
                        onPressed: () async {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            FocusScope.of(context).unfocus();
                          });
                          _loginuser();
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          final usertoken = prefs.getString('user_token');
                          print('#### yelo token');
                          print(usertoken);
                        },
                        child: _isLoading
                            ? LoadingAnimationWidget.inkDrop(
                            color: Colors.white,
                            size: 25.sp
                                
                                
                              )
                            : Text(
                                'Login',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50.h,
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
        ));
  }
}
