import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/auth_apis/setprofile.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection_anony.dart';
import 'package:socialmedia/utils/colors.dart';

class Interests extends StatefulWidget {
  final String user_id;
  final String token;
  const Interests({super.key, required this.user_id, required this.token});

  @override
  State<Interests> createState() => _InterestsState();
}

class _InterestsState extends State<Interests> {
  final List<String> allInterests = [
    'Memes',
    'Food & Culinary',
    'Pop Culture',
    'Gaming',
    'Health',
    'Outdoor Adventures',
    'Music',
    'Movies',
    'TV Shows',
    'Pets',
    'Fitness',
    'Travel',
    'Photography',
    'Technology',
    'DIY',
    'Fashion',
    'Literature',
    'Comedy',
    'Social Activism',
    'Social Media',
    'Craft Mixology',
    'Podcasts',
    'Cultural Arts',
    'History',
    'Science',
    'Auto Enthusiasts',
    'Meditation',
    'Virtual Reality',
    'Dance',
    'Board Games',
    'Wellness',
    'Trivia',
    'Content Creation',
    'Graphic Arts',
    'Anime',
    'Sports',
    'Stand-Up',
    'Crafts',
    'Exploration',
    'Concerts',
    'Musicians',
    'Animal Lovers',
    'Visual Arts',
    'Animation',
    'Style',
    'Basketball',
    'Football',
    'Hockey',
    'Boxing',
    'MMA',
    'Wrestling',
    'Baseball',
    'Golf',
    'Tennis',
    'Track & Field',
    'Gadgets',
    'Mathematics',
    'Physics',
    'Outer Space',
    'Religious',
    'Culture'
  ];

  final Set<String> selectedInterests = {};
  bool showAllInterests = false;

  List<String> get displayedInterests {
    return showAllInterests ? allInterests : allInterests.take(15).toList();
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
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark ? AppColors.darkGradient : AppColors.lightGradient,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Text(
                    'What Are\nYour Interests ?',
                    style: GoogleFonts.montserrat(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Text(
                    'Select Your Interests',
                    style: GoogleFonts.montserrat(fontSize: 20.sp, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade600),
                  ),
                ),
                SizedBox(height: 30.h),

                // Available Interests Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: displayedInterests.map((interest) {
                            final isSelected = selectedInterests.contains(interest);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedInterests.remove(interest);
                                  } else {
                                    selectedInterests.add(interest);
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).brightness == Brightness.dark
                                          ? Color(0xFF7400A5)
                                          : Color(0xFF7400A5)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? Color(0xFF7400A5) : Colors.grey.shade800,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      interest,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : (isSelected ? Colors.white : Colors.black),
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      SizedBox(width: 4.w),
                                      Icon(Icons.close, size: 16, color: Colors.white)
                                    ] else ...[
                                      SizedBox(width: 4.w),
                                      Icon(Icons.add, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        // Show More Button
                        if (!showAllInterests)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF7400A5) : Color(0xFF7400A5),
                                )),
                            onPressed: () {
                              setState(() {
                                showAllInterests = true;
                              });
                            },
                            child: Text(
                              'Explore More +',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Color(0xFF7400A5),
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Button
                Padding(
                  padding: EdgeInsets.only(bottom: 45.h),
                  child: Center(
                    child: SafeArea(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(350.w, 56.h),
                          backgroundColor: Color(0xFF7400A5),
                        ),
                        // onPressed: () async {
                        //   if (selectedInterests.isEmpty) {
                        //     Fluttertoast.showToast(
                        //       msg:
                        //           "Select 1 interest", // The message you want to display
                        //       toastLength:
                        //           Toast.LENGTH_SHORT, // Duration of the toast
                        //       gravity: ToastGravity.BOTTOM, // Position of the toast
                        //       timeInSecForIosWeb: 1, // Duration for iOS web
                        //       backgroundColor:
                        //           Colors.black, // Background color of the toast
                        //       textColor: Colors.white, // Text color of the toast
                        //       fontSize: 16.0, // Font size of the toast message
                        //     );
                        //     return;
                        //   }
                        //   /*  print(selectedInterests);
                        //   final SharedPreferences prefs = await SharedPreferences.getInstance();
                        //   final String? username = prefs.getString('username');
                        //   final String? phone = prefs.getString('phone');
                        //   final String? dob = prefs.getString('dateofbirth');
                        //   final String? bio = prefs.getString('bio');
                        //   editProfile(
                        //     context,
                        //     name: username.toString(),
                        //     interests: selectedInterests.toList(),
                        //     address: dob.toString(),
                        //     userId: widget.user_id,
                        //     token: widget.token
                        //   );*/
                        //   Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //           builder: (context) => AvatarSelectionScreen(
                        //                 userId: widget.user_id,
                        //                 token: widget.token,
                        //                 selectedInterests: selectedInterests,
                        //               )));
                        // },
                        onPressed: () async {
                          if (selectedInterests.length < 3) {
                            Fluttertoast.showToast(
                              msg: "Select At Least 3 Interests",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                            return;
                          }

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AvatarSelectionScreen(
                                        userId: widget.user_id,
                                        token: widget.token,
                                        selectedInterests: selectedInterests,
                                      )));
                        },
                        child: Text(
                          "Let's go",
                          style: GoogleFonts.montserrat(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
