import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:socialmedia/user_apis/uploadstory.dart';
import 'package:socialmedia/users/storyviewofmyusers.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/utils/storyAvatar.dart';

class StoryUtils {
  static Future<void> checkAndShowStoryOptions(
      BuildContext context,
      String userId,
      String token,
      Future<void> Function(ImageSource source) pickImageCallback, // Callback to pick image
      void Function(BuildContext context, String userId, List<Story_Item> stories) showStoryCallback) async {
    final response = await http.get(
      Uri.parse('${BASE_URL}api/get-self-stories'),
      headers: {
        'userId': userId,
        'token': token,
      },
    );

    if (response.statusCode == 200) {
      void _selectImageSource() {
        showModalBottomSheet(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          context: context,
          builder: (context) => Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      pickImageCallback(ImageSource.camera);
                    },
                    child: Container(
                      //  color: Colors.transparent,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(22.sp),
                        border: Border.all(color: Color(0xFF7400A5)),
                      ),
                      height: 60.h,
                      width: MediaQuery.of(context).size.width - 80,
                      child: Center(
                        child: Text(
                          'Take Photo',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      pickImageCallback(ImageSource.gallery);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(22.sp),
                        border: Border.all(color: Color(0xFF7400A5)),
                      ),
                      height: 60.h,
                      width: MediaQuery.of(context).size.width - 80,
                      child: Center(
                        child: Text(
                          'Choose From Gallery',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final data = json.decode(response.body);
      final List<dynamic> userStories = data['stories'];
      print('User stories: $userStories');
      showModalBottomSheet(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        context: context,
        builder: (context) => Container(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          padding: EdgeInsets.all(16),
          child: SafeArea(
            child: Container(
              width: double.infinity - 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16),
                  if (userStories.isEmpty)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _selectImageSource();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22.sp),
                          border: Border.all(color: Color(0xFF7400A5)),
                        ),
                        height: 60.h,
                        width: MediaQuery.of(context).size.width - 40,
                        child: Center(
                          child: Text(
                            'Upload Story',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    )
                  // ElevatedButton(
                  //   onPressed: ()  {
                  //     Navigator.pop(context);
                  //     _selectImageSource(); // Proceed to upload story
                  //   },
                  //   child: Text(
                  //     'Upload Story',
                  //     style: GoogleFonts.poppins(
                  //         fontSize: 14.sp, color: Colors.white),
                  //   ),
                  // )
                  else ...[
                    InkWell(
                      onTap: () {
                        print('yaha hua');
                        Navigator.pop(context);
                        showStoryCallback(
                          context,
                          userId,
                          userStories.map((story) => Story_Item.fromJson(story)).toList(),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(22.sp), border: Border.all(color: Color(0xFF7400A5))),
                        height: 60.h,
                        width: MediaQuery.of(context).size.width - 40,
                        child: Center(
                          child: Text(
                            'My Story',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.pop(context);
                    //     showStoryCallback(
                    //       context,
                    //       userId,
                    //       userStories
                    //           .map((story) => Story_Item.fromJson(story))
                    //           .toList(),
                    //     );
                    //   },
                    //   child: Text(
                    //     'My Story',
                    //     style: GoogleFonts.poppins(
                    //         fontSize: 14.sp, color: Color(0xFF7400A5)),
                    //   ),
                    // ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _selectImageSource();
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(22.sp), border: Border.all(color: Color(0xFF7400A5))),
                        height: 60.h,
                        width: MediaQuery.of(context).size.width - 40,
                        child: Center(
                          child: Text(
                            'Upload Story',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ElevatedButton(
                    //   onPressed: ()  {
                    //     Navigator.pop(context);
                    //      _selectImageSource(); // Proceed to upload a new story
                    //   },
                    //   child: Text(
                    //     'Upload Story',
                    //     style: GoogleFonts.poppins(
                    //         fontSize: 14.sp, color: Colors.white),
                    //   ),
                    // ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
