import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/pages/onboarding_screens/login_screen.dart';

class AvatarSelection extends StatefulWidget {
  const AvatarSelection({super.key});

  @override
  State<AvatarSelection> createState() => _AvatarSelectionState();
}

class _AvatarSelectionState extends State<AvatarSelection> {
  final List<String> images = [
    'assets/avatar/1.png',
    'assets/avatar/2.png',
    'assets/avatar/3.png',
    'assets/avatar/4.png',
    'assets/avatar/5.png',
    'assets/avatar/6.png',
    'assets/avatar/7.png',
    'assets/avatar/8.png',
    'assets/avatar/9.png',
    'assets/avatar/10.png'
  ];
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: Text(
                  "Let's Get You\nA Cool Style",
                  style: GoogleFonts.montserrat(
                    fontSize: 31.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: Text(
                  'Select Avatar',
                  style: GoogleFonts.montserrat(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 40.h,
                    childAspectRatio: 1, // Ratio of width to height (square items)
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedIndex == index ? Color(0xFF7400A5) : Colors.transparent,
                            width: 3.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.asset(
                            images[index],
                            fit: BoxFit.cover, // Ensures the image fills the container
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Center(
                  child: SafeArea(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: Size(350.w, 56.h), backgroundColor: Color(0xFF7400A5)),
                        onPressed: () async {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: Text(
                          "let's Go",
                          style: GoogleFonts.montserrat(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black),
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
