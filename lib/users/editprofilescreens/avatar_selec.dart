// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/auth_apis/setprofile.dart';
// import 'package:socialmedia/users/edit_profile.dart';
// import 'package:socialmedia/utils/colors.dart';
// import 'dart:convert';

// import 'package:socialmedia/utils/constants.dart';

// class AvatarSelectionScreenforsetting extends StatefulWidget {
//   const AvatarSelectionScreenforsetting({
//     Key? key,
//   }) : super(key: key);

//   @override
//   _AvatarSelectionScreenforsettingState createState() => _AvatarSelectionScreenforsettingState();
// }

// class _AvatarSelectionScreenforsettingState extends State<AvatarSelectionScreenforsetting> {
//   List<String> avatarUrls = [];
//   String? selectedAvatar;

//   @override
//   void initState() {
//     super.initState();
//     fetchAvatars();
//   }

//   Future<void> fetchAvatars() async {
//     try {
//       // Fetch userId and token from SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? userId = prefs.getString('user_id');
//       String? token = prefs.getString('user_token');

//       if (userId == null || token == null) {
//         print('User ID or Token is missing');
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('${BASE_URL}api/get-avatars'),
//         headers: {
//           'userid': userId,
//           'token': token,
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success']) {
//           List<String> maleAvatars = (data['URLS']['male'] as List).map((e) => e['url'].toString()).toList();
//           List<String> femaleAvatars = (data['URLS']['female'] as List).map((e) => e['url'].toString()).toList();

//           setState(() {
//             avatarUrls = [
//               ...maleAvatars.take(12),
//               ...femaleAvatars.take(12)
//             ]; // Show 12 male + 12 female avatars
//           });
//         }
//       } else {
//         print('Failed to fetch avatars: ${response.statusCode}');
//       }
//     } catch (e) {
//       print("Error fetching avatars: $e");
//     }
//   }

//   void _onAvatarSelected(String url) {
//     setState(() {
//       selectedAvatar = url;
//     });
//   }

//   // void _onProceed() async {
//   //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> EditProfileScreen(avatar: selectedAvatar!,  selectedInterests: <String>[] ,)));
//   // }
//   void _onProceed() async {
//     if (selectedAvatar != null) {
//       Navigator.pop(context, selectedAvatar);
//     } else {
//       Fluttertoast.showToast(
//         msg: "Please select an avatar first",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: 20,
//             ),
//             Text(
//               "Let's Get You\nA Cool Style",
//               style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 5),
//             Text(
//               "Edit your avatar",
//               style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
//             ),
//             SizedBox(height: 20),
//             Expanded(
//               child: avatarUrls.isEmpty
//                   ? Center(child: CircularProgressIndicator(color: Colors.white))
//                   : GridView.builder(
//                       itemCount: avatarUrls.length,
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 4,
//                         crossAxisSpacing: 10.w,
//                         mainAxisSpacing: 40.h,
//                       ),
//                       itemBuilder: (context, index) {
//                         String avatarUrl = avatarUrls[index];
//                         bool isSelected = selectedAvatar == avatarUrl;
//                         return GestureDetector(
//                           onTap: () => _onAvatarSelected(avatarUrl),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 3) : null,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(10),
//                               child: Image.network(avatarUrl, fit: BoxFit.cover),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//             SizedBox(height: 20),
//             SafeArea(
//               child: GestureDetector(
//                 onTap: _onProceed,
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(vertical: 15),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF7400A5) : AppColors.lightButton,
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     "Let's go",
//                     style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/auth_apis/setprofile.dart';
import 'package:socialmedia/users/edit_profile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'dart:convert';

import 'package:socialmedia/utils/constants.dart';

class AvatarSelectionScreenforsetting extends StatefulWidget {
  const AvatarSelectionScreenforsetting({
    Key? key,
  }) : super(key: key);

  @override
  _AvatarSelectionScreenforsettingState createState() => _AvatarSelectionScreenforsettingState();
}

class _AvatarSelectionScreenforsettingState extends State<AvatarSelectionScreenforsetting> with SingleTickerProviderStateMixin {
  List<String> maleAvatarUrls = [];
  List<String> femaleAvatarUrls = [];
  String? selectedAvatar;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAvatars();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchAvatars() async {
    try {
      // Fetch userId and token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? token = prefs.getString('user_token');

      if (userId == null || token == null) {
        print('User ID or Token is missing');
        return;
      }

      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-avatars'),
        headers: {
          'userid': userId,
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            maleAvatarUrls = (data['URLS']['male'] as List).map((e) => e['url'].toString()).toList();
            femaleAvatarUrls = (data['URLS']['female'] as List).map((e) => e['url'].toString()).toList();
          });
        }
      } else {
        print('Failed to fetch avatars: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching avatars: $e");
    }
  }

  void _onAvatarSelected(String url) {
    setState(() {
      selectedAvatar = url;
    });
  }

  void _onProceed() async {
    if (selectedAvatar != null) {
      Navigator.pop(context, selectedAvatar);
    } else {
      Fluttertoast.showToast(
        msg: "Please select an avatar first",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Widget _buildAvatarGrid(List<String> avatars) {
    return avatars.isEmpty
        ? Center(child: CircularProgressIndicator(color: Colors.white))
        : GridView.builder(
            itemCount: avatars.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 40.w,
              mainAxisSpacing: 20.h,
            ),
            itemBuilder: (context, index) {
              String avatarUrl = avatars[index];
              bool isSelected = selectedAvatar == avatarUrl;
              return GestureDetector(
                onTap: () => _onAvatarSelected(avatarUrl),
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 3) : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(avatarUrl, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.lightText : AppColors.darkText,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                "Let's Get You\nA Cool Style",
                style: GoogleFonts.roboto(color: isDarkMode ? AppColors.darkText : AppColors.lightText, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Edit your avatar",
                style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 20),

              // Tab Bar similar to the image provided
              Container(
                height: 45.h,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Color(0xFF7400A5),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  indicatorColor: Colors.transparent,
                  indicatorWeight: 0,
                  dividerColor: Colors.transparent,
                  // Remove the default indicator padding
                  indicatorPadding: EdgeInsets.zero,
                  // Use labelPadding to ensure proper text positioning
                  labelPadding: EdgeInsets.zero,
                  // This is important to make the indicator fill half of the container
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Male'),
                    Tab(text: 'Female'),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvatarGrid(maleAvatarUrls),
                    _buildAvatarGrid(femaleAvatarUrls),
                  ],
                ),
              ),

              SizedBox(height: 20),
              SafeArea(
                child: GestureDetector(
                  onTap: _onProceed,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF7400A5) : Color(0xFF7400A5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Let's go",
                      style: GoogleFonts.roboto(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
}
