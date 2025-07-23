// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/auth_apis/setprofile.dart';
// import 'package:socialmedia/community/joinCommunityWhileOnboarding.dart';
// import 'package:socialmedia/utils/colors.dart';
// import 'dart:convert';

// import 'package:socialmedia/utils/constants.dart';

// class AvatarSelectionScreen extends StatefulWidget {
//   final String userId;
//   final String token;
//   final Set<String> selectedInterests;

//   const AvatarSelectionScreen({Key? key, required this.userId, required this.token, required this.selectedInterests}) : super(key: key);

//   @override
//   _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
// }

// class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
//   List<String> avatarUrls = [];
//   String? selectedAvatar;

//   @override
//   void initState() {
//     super.initState();
//     fetchAvatars();
//   }

//   Future<void> fetchAvatars() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${BASE_URL}api/get-avatars'),
//         headers: {
//           'userid': widget.userId,
//           'token': widget.token,
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
//             ]; // Show 6 male + 6 female avatars
//           });
//         }
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
//   //   if (selectedAvatar != null) {
//   //     final SharedPreferences prefs = await SharedPreferences.getInstance();
//   //     final String? username = prefs.getString('username');
//   //     final String? phone = prefs.getString('phone');
//   //     final String? dob = prefs.getString('dateofbirth');
//   //     final String? bio = prefs.getString('bio');
//   //     editProfile(context,
//   //         name: username.toString(),
//   //         interests: widget.selectedInterests.toList(),
//   //         address: dob.toString(),
//   //         userId: widget.userId,
//   //         token: widget.token,
//   //         bio: bio!,
//   //         dob: dob.toString(),
//   //         avatar: selectedAvatar!
//   //         );

//   //   } else {

//   //     Fluttertoast.showToast(
//   //       msg: "Please select an avatar!",
//   //       toastLength: Toast.LENGTH_SHORT,
//   //       gravity: ToastGravity.BOTTOM,
//   //       backgroundColor: Colors.red,
//   //       textColor: Colors.white,
//   //     );
//   //   }
//   // }
//   void _onProceed() async {
//     if (selectedAvatar != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => JoinCommunitiesScreen(
//             userId: widget.userId,
//             token: widget.token,
//             selectedInterests: widget.selectedInterests,
//             selectedAvatar: selectedAvatar!,
//           ),
//         ),
//       );
//     } else {
//       Fluttertoast.showToast(
//         msg: "Please select an avatar!",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
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
//               "Select Avatar",
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
//                     style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold),
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
import 'package:socialmedia/community/joinCommunityWhileOnboarding.dart';
import 'package:socialmedia/utils/colors.dart';
import 'dart:convert';

import 'package:socialmedia/utils/constants.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Set<String> selectedInterests;

  const AvatarSelectionScreen({Key? key, required this.userId, required this.token, required this.selectedInterests}) : super(key: key);

  @override
  _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> with SingleTickerProviderStateMixin {
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
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-avatars'),
        headers: {
          'userid': widget.userId,
          'token': widget.token,
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JoinCommunitiesScreen(
            userId: widget.userId,
            token: widget.token,
            selectedInterests: widget.selectedInterests,
            selectedAvatar: selectedAvatar!,
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: "Please select an avatar!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
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
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 0, 0, 0),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        
        backgroundColor: isDarkMode ? AppColors.lightText : AppColors.darkText,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's Get You\nA Cool Style",
                style: GoogleFonts.roboto(color: isDarkMode ? AppColors.darkText : AppColors.lightText, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Select Avatar",
                style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 20),

              // Tab Bar
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
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  indicatorWeight: 0,
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

              SizedBox(height: 20),

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
                      style: GoogleFonts.roboto(color: isDarkMode ? Colors.white : AppColors.darkText, fontSize: 16.sp, fontWeight: FontWeight.bold),
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
