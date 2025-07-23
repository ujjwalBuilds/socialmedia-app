import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:socialmedia/auth_apis/setorupdatepass.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/svg.dart';
import '../../utils/constants.dart';
import '../../utils/colors.dart';

class UserInputFields extends StatefulWidget {
  final String userid;
  final String token;
  const UserInputFields({super.key, required this.userid, required this.token});

  @override
  State<UserInputFields> createState() => _UserInputFieldsState();
}

class _UserInputFieldsState extends State<UserInputFields> {
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController referral = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController bio = TextEditingController();
  TextEditingController dob = TextEditingController();

  bool _isLoading = false;
  bool _isRewritingBio = false;
  bool _passwordVisible = false;

  void _setpassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await setPassword(context, password.text, widget.userid, widget.token);
    } catch (e) {
      print("Error sending OTP: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final today = DateTime.now();
      final age = today.year - pickedDate.year - 
          (today.month < pickedDate.month || 
          (today.month == pickedDate.month && today.day < pickedDate.day) ? 1 : 0);

      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Center(child: Text('You must be at least 18 years old to register'))),
        );
        return;
      }

      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      setState(() {
        dob.text = formattedDate;
      });
    }
  }

  void _rewriteBioWithBondChat() async {
    if (bio.text.isEmpty) return;

    bio.selection = TextSelection(
      baseOffset: 0,
      extentOffset: bio.text.length,
    );

    setState(() => _isRewritingBio = true);

    try {
      final response = await http.post(
        Uri.parse("${BASE_URL}api/reWriteWithBond"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"caption": bio.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bio.text = data["rewritten"];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to rewrite bio. Please try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred. Please try again.")),
      );
    } finally {
      setState(() => _isRewritingBio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 16, 24, 43),
          leading: Navigator.canPop(context) 
            ? IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            )
            : null,
        ),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkGradient 
                    : AppColors.lightGradient,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),
                Padding(
                  padding: EdgeInsets.only(left: 38.w),
                  child: Text(
                    'Welcome to\nBondBridge',
                    style: GoogleFonts.montserrat(
                      fontSize: 30.sp, 
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.darkText 
                          : AppColors.lightText, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.only(left: 38.w),
                  child: Text(
                    'Enter Info',
                    style: GoogleFonts.montserrat(
                      fontSize: 20.sp, 
                      fontWeight: FontWeight.w400, 
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF999999) 
                          : Colors.grey.shade600
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: TextField(
                    controller: username,
                    decoration: InputDecoration(
                      hintText: "Username",
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 16.sp,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white70 
                            : AppColors.lightText,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF7400A5),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF7400A5),
                          width: 2,
                        ),
                      )
                    ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.darkText 
                          : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        maxLines: 4,
                        maxLength: 150,
                        keyboardType: TextInputType.multiline,
                        controller: bio,
                        decoration: InputDecoration(
                          hintText: "Bio",
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 16.sp,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : AppColors.lightText,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          counterText: "",
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7400A5),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7400A5),
                              width: 2,
                            ),
                          )
                        ),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkText 
                              : AppColors.lightText,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _isRewritingBio ? null : _rewriteBioWithBondChat,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(54.r),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.grey[100],
                                border: Border.all(color: const Color(0xFF7400A5))),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 4),
                                  _isRewritingBio
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF7400A5),
                                          ),
                                        )
                                      : Text(
                                          'Re-write with ',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                  ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) => const LinearGradient(
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                      colors: [
                                        Color(0xFF3B01B7),
                                        Color(0xFF5E00FF),
                                        Color(0xFFBA19EB),
                                        Color(0xFFDD0CC8),
                                      ],
                                    ).createShader(
                                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                    ),
                                    child: Text(
                                      'BondChat',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  SvgPicture.asset(
                                    'assets/icons/bondchat_star.svg',
                                    width: 15.w,
                                    height: 15.h,
                                  )
                                ],
                              ),
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: bio,
                            builder: (context, value, child) {
                              return Text(
                                '${value.text.length}/150',
                                style: GoogleFonts.montserrat(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: TextField(
                    controller: dob,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      hintText: "(D.O.B) dd/mm/yyyy",
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 16.sp,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white70 
                            : AppColors.lightText,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF7400A5),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF7400A5),
                          width: 2,
                        ),
                      )
                    ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.darkText 
                          : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: StatefulBuilder(builder: (context, setState) {
                    return TextField(
                      controller: password,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 16.sp,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : AppColors.lightText,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF7400A5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF7400A5),
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                            color: _passwordVisible ? const Color(0xFF7400A5) : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkText 
                            : AppColors.lightText,
                      ),
                    );
                  }),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: TextField(
                    controller: referral,
                    decoration: InputDecoration(
                      hintText: "Referral Code (Optional)",
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 16.sp,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white70 
                            : AppColors.lightText,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF7400A5),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF7400A5),
                          width: 2,
                        ),
                      )
                    ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.darkText 
                          : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 45.h,
                    top: 20.h,
                    left: 38.w,
                    right: 38.w,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56.h),
                      backgroundColor: const Color(0xFF7400A5),
                    ),
                    onPressed: () async {
                      final DateFormat format = DateFormat('dd/MM/yyyy');
                      try {
                        final DateTime birthDate = format.parse(dob.text);
                        final DateTime today = DateTime.now();
    
                        int age = today.year - birthDate.year;
                        if (today.month < birthDate.month || 
                            (today.month == birthDate.month && today.day < birthDate.day)) {
                          age--;
                        }
    
                        if (age < 18) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF7400A5),
                              content: Center(
                                child: Text(
                                  'You must be at least 18 years old to register',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )),
                          );
                          return;
                        }
    
                        final prefs_username = await SharedPreferences.getInstance();
                        String capitalizedUsername = username.text.isNotEmpty 
                            ? username.text[0].toUpperCase() + username.text.substring(1) 
                            : '';
                        await prefs_username.setString('username', capitalizedUsername);
                        await prefs_username.setString('dateofbirth', dob.text);
                        await prefs_username.setString('bio', bio.text);
                        await prefs_username.setString('referral', referral.text);
                        _setpassword();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Center(child: Text('Please enter a valid date of birth'))
                          ),
                        );
                      }
                    },
                    child: _isLoading
                        ? const SimpleCircularProgressBar(
                            size: 20,
                            progressStrokeWidth: 4,
                            backStrokeWidth: 0,
                            progressColors: [Colors.white, Colors.yellow],
                          )
                        : Text(
                            'Let\'s Go',
                            style: GoogleFonts.montserrat(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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