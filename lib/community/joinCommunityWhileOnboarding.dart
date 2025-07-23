// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/explore_screen.dart';
// import 'package:socialmedia/community/communityModel.dart';
// import 'dart:convert';
// import 'package:socialmedia/utils/colors.dart';
// import 'package:socialmedia/auth_apis/setprofile.dart';
// import 'package:socialmedia/utils/constants.dart';

// class JoinCommunitiesScreen extends StatefulWidget {
//   final String userId;
//   final String token;
//   final Set<String> selectedInterests;
//   final String selectedAvatar;

//   const JoinCommunitiesScreen({
//     Key? key,
//     required this.userId,
//     required this.token,
//     required this.selectedInterests,
//     required this.selectedAvatar,
//   }) : super(key: key);

//   @override
//   _JoinCommunitiesScreenState createState() => _JoinCommunitiesScreenState();
// }

// class _JoinCommunitiesScreenState extends State<JoinCommunitiesScreen> {
//   List<Community> communities = [];
//   bool isLoading = true;
//   Set<String> selectedCommunities = {};

//   @override
//   void initState() {
//     super.initState();
//     fetchCommunities();
//   }

//   Future<void> fetchCommunities() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${BASE_URL_COMMUNITIES}api/communities'),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         final List<dynamic> communitiesJson = jsonResponse['communities'];

//         setState(() {
//           communities = communitiesJson.map((json) => Community.fromJson(json)).toList();
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error fetching communities: $e");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _onCommunitySelected(String id) {
//     setState(() {
//       if (selectedCommunities.contains(id)) {
//         selectedCommunities.remove(id);
//       } else {
//         selectedCommunities.add(id);
//       }
//     });
//   }

//   void _onProceed(BuildContext context) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? username = prefs.getString('username');
//     final String? phone = prefs.getString('phone');
//     final String? dob = prefs.getString('dateofbirth');
//     final String? bio = prefs.getString('bio');

//     editProfile(context, name: username.toString(), interests: widget.selectedInterests.toList(), address: dob.toString(), userId: widget.userId, token: widget.token, bio: bio!, dob: dob.toString(), avatar: widget.selectedAvatar);

//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 const Color(0xFF000000),
//                 const Color(0xFF0A0A1A),
//                 const Color(0xFF0F0F2D),
//               ],
//             ),
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 30),
//                   Text(
//                     "Explore Exciting\nCommunities",
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Select Communities",
//                     style: GoogleFonts.roboto(
//                       color: Colors.grey,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Expanded(
//                     child: isLoading
//                         ? const Center(child: CircularProgressIndicator(color: Colors.white))
//                         : GridView.builder(
//                             gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 3,
//                               crossAxisSpacing: 5.w,
//                               mainAxisSpacing: 30.h,
//                               childAspectRatio: 0.635,
//                             ),
//                             itemCount: communities.length,
//                             itemBuilder: (context, index) {
//                               return _buildCommunityCard(communities[index]);
//                             },
//                           ),
//                   ),
//                    SizedBox(height: 20.h),
//                   SafeArea(
//                     child: GestureDetector(
//                       onTap: () => _onProceed(context),
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         decoration: BoxDecoration(
//                           color: Color(0xFF7400A5),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         alignment: Alignment.center,
//                         child: Text(
//                           "Let's go",
//                           style: GoogleFonts.roboto(
//                             color: Colors.white,
//                             fontSize: 16.sp,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCommunityCard(Community community) {
//     bool isSelected = selectedCommunities.contains(community.id);

//     return GestureDetector(
//       onTap: () => _onCommunitySelected(community.id),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16.sp),
//           border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 2) : null,
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               // Background image with overlay
//               Opacity(
//                 opacity: 0.7,
//                 child: community.backgroundImage.isNotEmpty
//                     ? Image.network(
//                         community.backgroundImage,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Image.network(
//                             'https://picsum.photos/200',
//                             fit: BoxFit.cover,
//                           );
//                         },
//                       )
//                     : Image.network(
//                         'https://picsum.photos/200',
//                         fit: BoxFit.cover,
//                       ),
//               ),
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.transparent,
//                       Colors.black.withOpacity(0.7),
//                     ],
//                   ),
//                 ),
//               ),

//               // Community profile image and info
//               Padding(
//                 padding: EdgeInsets.all(12.0.w),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircleAvatar(
//                       radius: 30.sp,
//                       backgroundColor: Colors.grey[300],
//                       backgroundImage: community.profilePicture.isNotEmpty ? NetworkImage(community.profilePicture) : const NetworkImage('https://picsum.photos/100'),
//                       onBackgroundImageError: (exception, stackTrace) {
//                         // Fallback if profile image fails to load
//                       },
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       community.name,
//                       textAlign: TextAlign.center,
//                       style: GoogleFonts.roboto(
//                         color: Colors.white,
//                         fontSize: 15.sp,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       "Members: ${community.membersCount}",
//                       style: GoogleFonts.roboto(
//                         color: Colors.grey[400],
//                         fontSize: 12.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'dart:convert';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/auth_apis/setprofile.dart';
import 'package:socialmedia/utils/constants.dart';

class JoinCommunitiesScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Set<String> selectedInterests;
  final String selectedAvatar;

  const JoinCommunitiesScreen({
    Key? key,
    required this.userId,
    required this.token,
    required this.selectedInterests,
    required this.selectedAvatar,
  }) : super(key: key);

  @override
  _JoinCommunitiesScreenState createState() => _JoinCommunitiesScreenState();
}

class _JoinCommunitiesScreenState extends State<JoinCommunitiesScreen> {
  List<Community> communities = [];
  bool isLoading = true;
  bool isSaving = false;
  Set<String> selectedCommunities = {};

  @override
  void initState() {
    super.initState();
    fetchCommunities();
  }

  Future<void> fetchCommunities() async {
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> communitiesJson = jsonResponse['communities'];

        setState(() {
          communities = communitiesJson.map((json) => Community.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching communities: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onCommunitySelected(String id) {
    setState(() {
      if (selectedCommunities.contains(id)) {
        selectedCommunities.remove(id);
      } else {
        selectedCommunities.add(id);
      }
    });
  }

  Future<bool> joinOrLeaveCommunity(String userId, List<String> communityIds, String action) async {
    final url = Uri.parse('${BASE_URL_COMMUNITIES}api/users/joincommunity');
    final headers = {
      'Content-Type': 'application/json',
      'userId': userId,
      if (widget.token.isNotEmpty) 'token': widget.token,
    };

    final body = jsonEncode({
      'communityIds': communityIds,
      'userId': userId,
      'action': action, // "join" or "remove"
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('Successfully performed action: $action');
        return true;
      } else {
        print('Failed to perform action: $action. Status code: ${response.statusCode}');
        print('Failed to perform action: $action. Status code: ${response.body}');
        return false;
      }
    } catch (e) {
      print('An error occurred: $e');
      return false;
    }
  }

  void _onProceed(BuildContext context) async {
    // Show loading indicator while saving
    setState(() {
      isSaving = true;
    });
    
    // Join selected communities
    bool success = await joinOrLeaveCommunity(widget.userId, selectedCommunities.toList(), "join");

    if (success) {
      print("Successfully joined communities!");

      // Proceed with profile update or navigation
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? username = prefs.getString('username');
      final String? phone = prefs.getString('phone');
      final String? dob = prefs.getString('dateofbirth');
      final String? bio = prefs.getString('bio');
      final String? referralCode = prefs.getString('referral');

      editProfile(
        context,
        name: username.toString(),
        interests: widget.selectedInterests.toList(),
        address: dob.toString(),
        userId: widget.userId,
        token: widget.token,
        bio: bio!,
        dob: dob.toString(),
        avatar: widget.selectedAvatar,
        referralCode: referralCode!,
      );
    } else {
      // Hide loading indicator if there was an error
      setState(() {
        isSaving = false;
      });
      
      print("Failed to join communities.");
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF000000),
                const Color(0xFF0A0A1A),
                const Color(0xFF0F0F2D),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Explore Exciting\nCommunities",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Select Communities",
                    style: GoogleFonts.roboto(
                      color: Colors.grey,
                      fontSize: 16.sp,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 5.w, mainAxisSpacing: 30.h, childAspectRatio: 0.635),
                            itemCount: communities.length,
                            itemBuilder: (context, index) {
                              return _buildCommunityCard(communities[index]);
                            },
                          ),
                  ),
                  SizedBox(height: 20.h),
                  SafeArea(
                    child: GestureDetector(
                      onTap: isSaving ? null : () => _onProceed(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(color: Color(0xFF7400A5), borderRadius: BorderRadius.circular(30)),
                        alignment: Alignment.center,
                        child: isSaving
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : Text("Let's go", style: GoogleFonts.roboto(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    bool isSelected = selectedCommunities.contains(community.id);

    return GestureDetector(
      onTap: () => _onCommunitySelected(community.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.sp),
          border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 2) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image with overlay
              Opacity(
                opacity: 0.7,
                child: community.backgroundImage.isNotEmpty
                    ? Image.network(
                        community.backgroundImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://picsum.photos/200',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.network(
                        'https://picsum.photos/200',
                        fit: BoxFit.cover,
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Community profile image and info
              Padding(
                padding: EdgeInsets.all(12.0.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30.sp,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: community.profilePicture.isNotEmpty ? NetworkImage(community.profilePicture) : const NetworkImage('https://picsum.photos/100'),
                      onBackgroundImageError: (exception, stackTrace) {
                        // Fallback if profile image fails to load
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      community.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Members: ${community.membersCount}",
                      style: GoogleFonts.roboto(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
