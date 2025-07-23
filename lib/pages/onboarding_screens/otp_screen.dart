import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart'; // Not used
import 'package:socialmedia/auth_apis/send_otp.dart';
import 'package:socialmedia/auth_apis/verify_otp.dart';
import 'package:pinput/pinput.dart';
import 'package:socialmedia/utils/colors.dart';

class OtpScreen extends StatefulWidget {
  final String number;
  final String countrycode;
  final String email;
  const OtpScreen(
      {super.key,
      required this.number,
      required this.countrycode,
      required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String finalotp = '';
  String? mobile;
  bool _isLoading = false;

  void _verifyotp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await verifyOtp(mobile.toString(), widget.countrycode, finalotp, context);
    } catch (e) {
      print("Error verifying OTP: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      mobile = widget.number;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setotp(String a) {
    setState(() {
      finalotp = a;
    });
    print(finalotp);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 16, 24, 43),
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return Container(
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
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 63.h,
                            ),
                            SizedBox(
                              height: 67.h,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 40.w),
                              child: SizedBox(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enter OTP',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 30.sp,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkText
                                            : AppColors.lightText,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Sent to $mobile ",
                                        style: GoogleFonts.montserrat(
                                            fontSize: 18.sp,
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF999999)
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      SizedBox(
                                        width: 8.w,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Edit',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 18.sp,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? AppColors.darkText
                                                  : AppColors.lightText,
                                              fontWeight: FontWeight.w400,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Colors.white),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              )),
                            ),
                            SizedBox(
                              height: 48.h,
                            ),
                            Center(
                              child: Pinput(
                                length: 6,
                                closeKeyboardWhenCompleted: true,
                                defaultPinTheme: PinTheme(
                                  width: 56,
                                  height: 60,
                                  textStyle: TextStyle(
                                      fontSize: 25,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkText
                                          : AppColors.lightText,
                                      fontWeight: FontWeight.w600),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkText
                                          : AppColors.lightText,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onCompleted: (pin) => setotp(pin),
                              ),
                            ),
                            SizedBox(
                              height: 25.h,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Didn't get the code?  ",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    OTPApiService().sendOtp(
                                        mobile.toString(),
                                        widget.countrycode,
                                        context,
                                        email: widget.email);
                                  },
                                  child: Text(
                                    "Resend it",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFFBE75FF)
                                          : const Color(0xFF7400A5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                          child: Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(350.w, 56.h),
                                backgroundColor: const Color(0xFF7400A5),
                              ),
                              onPressed: () {
                                _verifyotp();
                              },
                              child: _isLoading
                                  ? LoadingAnimationWidget.inkDrop(
                                      color: Colors.white, size: 30)
                                  : Text(
                                      'Verify OTP',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}