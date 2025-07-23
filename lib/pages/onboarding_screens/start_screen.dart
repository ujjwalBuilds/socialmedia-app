import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:socialmedia/pages/onboarding_screens/signup_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,

        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.50,
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Image.asset(
                      'assets/images/home_front_final.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Column(
                    children: [
                      SizedBox(height: 52.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: SizedBox(
                          height: 90.h,
                          width: 339.w,
                          child: RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              style: TextStyle(height: 1.4),
                              children: [
                                TextSpan(
                                  text: 'Welcome to ',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: "BondBridge, ",
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w700,
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: [
                                          Color(0xFF7E6DF1),
                                          Color(0xFF7E6DF1),
                                          Color(0xFF7E6DF1),
                                          Color(0xFF7E6DF1),
                                          Color(0xFF7E6DF1),
                                          Color(0xFFE25FB2),
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(0.0, 0.0, 315.0, 70.0),
                                      )
                                      ..strokeWidth = 2,
                                  ),
                                ),
                                TextSpan(
                                  text: 'a\nnew way to connect ',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: "online",
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w700,
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: [
                                          Color(0xFF7E6DF1),
                                          Color(0xFF7E6DF1),
                                          Color(0xFF7E6DF1),
                                          Color(0xFF7E6DF1),
                                          Color(0xFFE25FB2),
                                          Color(0xFFE25FB2),
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(0, 0, 480, 50),
                                      )
                                      ..strokeWidth = 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 10),
                        child: SizedBox(
                          height: 100,
                          child: SvgPicture.asset(
                            'assets/images/bondlogog.svg',
                            width: 130,
                            height: 130,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.w),
                        child: Container(
                          height: 80.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1E1F25),
                                Color(0xFF121318),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(45),
                          ),
                          child: SlideAction(
                            outerColor: Colors.transparent,
                            innerColor: Colors.white,
                            sliderButtonIcon: const Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: Colors.black,
                              size: 28,
                            ),
                            height: 80.h,
                            borderRadius: 45,
                            elevation: 0,
                            sliderRotate: false,
                            submittedIcon: const SizedBox.shrink(),
                            animationDuration: Duration.zero,
                            onSubmit: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const SignupScreen()),
                              );
                              return null;
                            },
                            child: Shimmer.fromColors(
                              period: const Duration(seconds: 1),
                              baseColor: const Color(0xff9C9C9C),
                              highlightColor: Colors.white,
                              child: Text(
                                "Swipe To Connect",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
