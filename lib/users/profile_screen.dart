// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
// import 'package:socialmedia/community/communityDetailedScreen.dart';
// import 'package:socialmedia/community/communityListView.dart';
// import 'package:socialmedia/community/communityModel.dart';
// import 'package:socialmedia/community/communityProvider.dart';
// import 'package:socialmedia/services/user_Service_provider.dart';
// import 'package:socialmedia/users/edit_profile.dart';
// import 'package:socialmedia/users/searched_userprofile.dart'
//     show VideoThumbnailWidget;
// import 'package:socialmedia/users/settings.dart';
// import 'package:socialmedia/users/show_post_content.dart';
// import 'package:socialmedia/users/userfollowinglist.dart';
// import 'package:socialmedia/utils/colors.dart';
// import 'package:socialmedia/utils/constants.dart';
// import 'package:switcher_button/switcher_button.dart';
// import 'package:tab_container/tab_container.dart';
// import 'package:video_player/video_player.dart';

// class user_profile extends StatefulWidget {
//   const user_profile({
//     super.key,
//   });

//   @override
//   State<user_profile> createState() => _user_profileState();
// }

// class _user_profileState extends State<user_profile>
//     with TickerProviderStateMixin {
//   String? Username;
//   String? nickname;
//   List<Map<String, dynamic>> posts = []; // State to hold the posts
//   String? selectedImageUrl; // State to track the selected image for preview
//   String? selectedImageContent;
//   int followers = 0;
//   int following = 0;
//   int postlength = 0;
//   bool isLoadingpost = true;
//   bool privacychecker = false;
//   bool isloadingprivacy = false;
//   bool isprofileloaded = false;
//   String? profilepic;
//   bool isonpost = true;
//   String bio = '';
//   late UserProviderall userProvider;
//   List<dynamic> interests = [];
//   bool showAllInterests = false;
//   bool isExpanded = false;
//   bool _showReadMore = false;
//   int communityCount = 0;
//   List<Community> communities = [];
//   bool isLoadingCommunities = true;
//   late TabController _tabController;
//   int _currentTabIndex = 0;
//   String? avatar;
//   Map<String, int> communityMemberCounts = {};


//   @override
//   void initState() {
//     super.initState();
//     _initializeProfile();
//     _tabController = TabController(length: 3, vsync: this);
//     _tabController.addListener(() {
//       setState(() {
//         _currentTabIndex = _tabController.index;
//       });
//     });
//    // _communitiesFuture = _fetchUserCommunities(userProvider.userId ?? '');
//   }

//   int get postsCount => posts
//       .where((post) =>
//           post['data']['media'] != null && post['data']['media'].isNotEmpty)
//       .length;
//   int get quotesCount => posts
//       .where((post) =>
//           post['data']['media'] == null || post['data']['media'].isEmpty)
//       .length;
//   // int get communityCount => 0;

//   Future<void> _initializeProfile() async {
//     if (!mounted) return;

//     userProvider = Provider.of<UserProviderall>(context, listen: false);
//     await userProvider.loadUserData();

//     if (!mounted) return;

//     await fetchProfile();
//     await fetchPosts();

//     if (!mounted) return;

//     setState(() {
//       isprofileloaded = true;
//     });
//   }

//   Future<void> _loadPrivacyState() async {
//     final prefs = await SharedPreferences.getInstance();
//   }

//   Future<void> _savePrivacyState(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('privacy_switch_value', value);
//   }

//   void _rebuildScreen() {
//     _initializeProfile();
//   }

//   Future<void> changeProfile(
//       BuildContext context, String userId, String token, String name) async {
//     final ImagePicker _picker = ImagePicker();
//     XFile? pickedFile;

//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext bc) {
//         return SafeArea(
//           child: Wrap(
//             children: <Widget>[
//               ListTile(
//                 leading: Icon(Icons.camera_alt),
//                 title: Text(
//                   'Take A Photo',
//                   style: GoogleFonts.poppins(fontSize: 14),
//                 ),
//                 onTap: () async {
//                   pickedFile =
//                       await _picker.pickImage(source: ImageSource.camera);
//                   Navigator.pop(context);
//                   if (pickedFile != null) {
//                     uploadImage(File(pickedFile!.path), userId, token, name);
//                   }
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.photo_library),
//                 title: Text('Choose From Gallery',
//                     style: GoogleFonts.poppins(fontSize: 14)),
//                 onTap: () async {
//                   pickedFile =
//                       await _picker.pickImage(source: ImageSource.gallery);
//                   Navigator.pop(context);
//                   if (pickedFile != null) {
//                     uploadImage(File(pickedFile!.path), userId, token, name);
//                   }
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.delete),
//                 title: Text('Delete Profile Pic',
//                     style:
//                         GoogleFonts.poppins(fontSize: 14, color: Colors.red)),
//                 onTap: () async {
//                   Navigator.pop(context);

//                   showDialog(
//                     context: context,
//                     barrierDismissible: false,
//                     builder: (BuildContext context) {
//                       return Center(
//                         child: CircularProgressIndicator(
//                           color: const Color(0xFF7400A5),
//                         ),
//                       );
//                     },
//                   );

//                   try {
//                     final SharedPreferences prefs =
//                         await SharedPreferences.getInstance();
//                     final String? userId = prefs.getString('user_id');
//                     final String? token = prefs.getString('user_token');

//                     if (userId == null || token == null) {
//                       throw Exception('User ID or token is missing');
//                     }

//                     final response = await http.delete(
//                       Uri.parse('${BASE_URL}api/profile-picture'),
//                       headers: {
//                         'userId': userId,
//                         'token': token,
//                       },
//                     );

//                     Navigator.pop(context);

//                     if (response.statusCode == 200) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Center(
//                             child: Text(
//                               'Profile picture deleted successfully',
//                               style: GoogleFonts.poppins(fontSize: 14),
//                             ),
//                           ),
//                           backgroundColor: Colors.green,
//                         ),
//                       );

//                       Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => user_profile()));
//                     } else {
//                       throw Exception(
//                           'Failed to delete profile picture: ${response.body}');
//                     }
//                   } catch (e) {
//                     if (Navigator.canPop(context)) {
//                       Navigator.pop(context);
//                     }

//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Center(
//                           child: Text(
//                             'Error: ${e.toString()}',
//                             style: GoogleFonts.poppins(fontSize: 14),
//                           ),
//                         ),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> uploadImage(
//       dynamic imageFile, String userId, String token, String name) async {
//     var uri = Uri.parse("${BASE_URL}api/edit-profile");

//     final request = http.MultipartRequest('PUT', uri)
//       ..headers.addAll({
//         'userId': userId,
//         'token': token,
//       });

//     if (imageFile is File) {
//       request.files.add(
//         await http.MultipartFile.fromPath('image', imageFile.path),
//       );
//     } else if (imageFile is String && imageFile.isEmpty) {
//       request.fields['image'] = '';
//     }

//     request.fields['name'] = name;

//     var response = await request.send();
//     var responseString = await response.stream.bytesToString();

//     print("Status Code: ${response.statusCode}");
//     print("Response: $responseString");

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (context) => user_profile()));
//       print("Image uploaded successfully");
//     } else {
//       print("Failed to upload image");
//     }
//   }

//   Future<void> _updatePrivacyLevel(bool value) async {
//     // Immediately update the UI state
//     setState(() {
//       privacychecker = value;
//       if (value) {
//         Username = nickname;
//       } else {
//         Username = profileData?['name'];
//       }
//     });

//     // Update the user provider to reflect the new privacy state and profile picture
//     if (mounted) {
//       final userProvider = Provider.of<UserProviderall>(context, listen: false);
//       userProvider.updatePrivacyState(value);
//       userProvider.updateProfilePic(profilepic);
//       userProvider.updateAvatar(avatar);
//     }

//     // Make API call in background
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('user_token') ?? '';
//       final userId = prefs.getString('user_id') ?? '';

//       final headers = {
//         'Content-Type': 'application/json',
//         'token': token,
//         'userId': userId,
//       };

//       final body = {
//         'privacyLevel': value ? 1 : 0,
//       };

//       final response = await http.put(
//         Uri.parse('${BASE_URL}api/edit-profile'),
//         headers: headers,
//         body: json.encode(body),
//       );

//       if (response.statusCode == 200) {
//         await _savePrivacyState(value);
//       } else {
//         // If API call fails, revert the state
//         if (mounted) {
//           setState(() {
//             privacychecker = !value;
//             if (!value) {
//               Username = nickname;
//             } else {
//               Username = profileData?['name'];
//             }
//           });
//           // Also revert the provider state
//           final userProvider =
//               Provider.of<UserProviderall>(context, listen: false);
//           userProvider.updatePrivacyState(!value);
//           userProvider.updateProfilePic(profilepic);
//           userProvider.updateAvatar(avatar);
//         }
//         throw Exception('Failed to update privacy level: ${response.body}');
//       }
//     } catch (e) {
//       print("Error updating privacy level: $e");
//       // State is already reverted if needed
//       rethrow;
//     }
//   }

//   Future<void> fetchPosts() async {
//     final String url = '${BASE_URL}api/get-posts';
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? userid = prefs.getString('user_id');
//     final String? token = prefs.getString('user_token');

//     if (userid == null || token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Center(child: Text('User ID or Token is missing.'))),
//       );
//       return;
//     }

//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'userid': userid,
//           'token': token,
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         final List<Map<String, dynamic>> allPosts =
//             List<Map<String, dynamic>>.from(data['posts']);
//         final List<Map<String, dynamic>> mediaOnlyPosts = allPosts
//             .where((post) =>
//                 post['data']['media'] != null &&
//                 post['data']['media'].isNotEmpty)
//             .toList();

//         setState(() {
//           posts = allPosts;
//           posts.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
//           isLoadingpost = false;
//         });
//       } else {
//         print('Failed to fetch posts: ${response.statusCode}');
//         setState(() {
//           isLoadingpost = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching posts: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content:
//                 Center(child: Text('An error occurred while fetching posts.'))),
//       );
//       setState(() {
//         isLoadingpost = false;
//       });
//     }
//   }

//   Map<String, dynamic>? profileData;
//   bool isLoading = false;

//   Future<void> fetchProfile() async {
//     if (!mounted) return;

//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? userid = prefs.getString('user_id');
//     final String? token = prefs.getString('user_token');

//     if (userid == null || token == null) {
//       print('User ID or token is missing');
//       return;
//     }

//     final Uri url = Uri.parse('${BASE_URL}api/showProfile?other=$userid');
//     final Map<String, String> headers = {
//       'Content-Type': 'application/json',
//       'userid': userid,
//       'token': token,
//     };

//     if (!mounted) return;
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final http.Response response = await http.get(url, headers: headers);

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = jsonDecode(response.body);
//         if (responseData['result'] != null &&
//             responseData['result'] is List &&
//             responseData['result'].isNotEmpty) {
//           final userDetails = responseData['result'][0];
//           log(responseData.toString());

//           if (!mounted) return;

//           setState(() {
//             followers = userDetails['followers'] ?? 0;
//             following = userDetails['followings'] ?? 0;
//             Username = userDetails['name'];
//             nickname = userDetails['nickName'] ?? 'Delta';
//             profileData = userDetails;
//             privacychecker = userDetails['privacyLevel'] == 1 ? true : false;
//             isloadingprivacy = true;
//             profilepic = userDetails['profilePic'];
//             avatar = userDetails['avatar'];
//             final int public = userDetails['public'] ?? 1;
//             userProvider.setPublicStatus(public);
//             bio = userDetails['bio'];
//             interests = userDetails['interests'] ?? [];

//             if (privacychecker) {
//               Username = nickname;
//             } else {
//               Username = userDetails['name'];
//             }
//           });
//         }
//       }
//     } catch (error) {
//       print('An error occurred: $error');
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   void _showImagePreview(String imageUrl, String content) {
//     setState(() {
//       selectedImageUrl = imageUrl;
//       selectedImageContent = content;
//     });
//   }

//   void _closeImagePreview() {
//     setState(() {
//       selectedImageUrl = null;
//     });
//   }

//   Widget _buildPostsTab() {
//     final mediaPosts = posts.where((post) {
//       final data = post['data'] as Map<String, dynamic>?;
//       final media = data?['media'] as List<dynamic>?;
//       return media != null && media.isNotEmpty;
//     }).toList();

//     if (isLoadingpost || mediaPosts.isEmpty) {
//       return Center(
//         child: Text(
//           'No Posts to show',
//           style: GoogleFonts.roboto(
//             fontSize: 16.sp,
//             fontWeight: FontWeight.w400,
//           ),
//         ),
//       );
//     }

//     // GridView that will be part of the main scroll
//     return GridView.builder(
//       padding: const EdgeInsets.all(8.0),
//       physics: const NeverScrollableScrollPhysics(), // disable inner scroll
//       shrinkWrap: true, // essential to calculate proper height
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 5,
//         mainAxisSpacing: 2,
//       ),
//       itemCount: mediaPosts.length,
//       itemBuilder: (context, index) {
//         final post = mediaPosts[index];
//         final data = post['data'] as Map<String, dynamic>?;
//         final mediaList = data?['media'] as List<dynamic>?;

//         String mediaUrl = '';
//         if (mediaList != null && mediaList.isNotEmpty) {
//           final firstMedia = mediaList[0] as Map<String, dynamic>?;
//           mediaUrl = firstMedia?['url'] as String? ?? '';
//         }

//         final bool isVideo = mediaUrl.toLowerCase().endsWith('.mp4') ||
//             mediaUrl.toLowerCase().endsWith('.mov') ||
//             mediaUrl.toLowerCase().endsWith('.webm') ||
//             mediaUrl.toLowerCase().contains('video');

//         return GestureDetector(
//           onTap: () {
//             final feedId = post['feedId'] as String?;
//             if (feedId != null) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => PostDetailsScreen(feedId: feedId),
//                 ),
//               );
//             }
//           },
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.grey[900],
//               borderRadius: BorderRadius.circular(16.sp),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(16.sp),
//               child: isVideo
//                   ? Stack(
//                       children: [
//                         VideoThumbnailWidget(videoUrl: mediaUrl),
//                         const Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Icon(
//                             Icons.play_circle_fill,
//                             size: 28,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     )
//                   : Image.network(
//                       mediaUrl,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           color: Colors.grey,
//                           child: const Center(
//                             child: Icon(Icons.error, color: Colors.red),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildThoughtsTab() {
//     final thoughtPosts = posts.where((post) {
//       final data = post['data'] as Map<String, dynamic>?;
//       final media = data?['media'] as List<dynamic>?;
//       return media == null || media.isEmpty;
//     }).toList();

//     return Container(
//       child: isLoadingpost
//           ? Center(
//               child: Text(
//                 'Loading thoughts...',
//                 style: GoogleFonts.roboto(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             )
//           : thoughtPosts.isEmpty
//               ? Center(
//                   child: Text(
//                     'No Quotes To Show',
//                     style: GoogleFonts.roboto(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 )
//               : ListView.builder(
//                   physics: NeverScrollableScrollPhysics(),
//                   shrinkWrap: true,
//                   itemCount: thoughtPosts.length,
//                   itemBuilder: (context, index) {
//                     final post = thoughtPosts[index];
//                     final data = post['data'] as Map<String, dynamic>?;
//                     final content = data?['content'] ?? 'No content';
//                     final createdAt = post['createdAt'] != null
//                         ? DateTime.fromMillisecondsSinceEpoch(
//                             post['createdAt'] * 1000)
//                         : null;
//                     final formattedDate = createdAt != null
//                         ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
//                         : '';
//                     final profilePic = post['profilePic'] as String? ?? '';
//                     final name = post['name'] as String? ?? 'Unknown';

//                     return GestureDetector(
//                       onTap: () {
//                         final feedId = post['feedId'] as String?;
//                         if (feedId != null) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   PostDetailsScreen(feedId: feedId),
//                             ),
//                           );
//                         }
//                       },
//                       child: Card(
//                         margin: EdgeInsets.symmetric(
//                             vertical: 8.h, horizontal: 16.w),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         color: const Color(0xFF2A2A3A),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   CircleAvatar(
//                                     backgroundImage: NetworkImage(privacychecker
//                                         ? post['avatar'] as String? ?? ''
//                                         : post['profilePic'] as String? ?? ''),
//                                     radius: 20,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Text(
//                                     name,
//                                     style: GoogleFonts.roboto(
//                                       color: Colors.white,
//                                       fontSize: 14.sp,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   const Spacer(),
//                                   Text(
//                                     formattedDate,
//                                     style: GoogleFonts.roboto(
//                                       color: Colors.grey,
//                                       fontSize: 12.sp,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Text(
//                                 content,
//                                 style: GoogleFonts.roboto(
//                                   color: Colors.white,
//                                   fontSize: 16.sp,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.end,
//                                 children: [
//                                   Icon(Icons.favorite_border,
//                                       color: Colors.grey, size: 18.sp),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     (post['reactionCount'] as int? ?? 0)
//                                         .toString(),
//                                     style: GoogleFonts.roboto(
//                                       color: Colors.grey,
//                                       fontSize: 12.sp,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Icon(Icons.chat_bubble_outline,
//                                       color: Colors.grey, size: 18.sp),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     (post['commentCount'] as int? ?? 0)
//                                         .toString(),
//                                     style: GoogleFonts.roboto(
//                                       color: Colors.grey,
//                                       fontSize: 12.sp,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }

//   Future<List<Community>> _fetchUserCommunities(String userId) async {
//     if (userId.isEmpty) return [];

//     try {
//       final token = userProvider.userToken ?? '';
//       final currentUserId = userProvider.userId ?? '';

//       final headers = {
//         'token': token,
//         'userid': currentUserId,
//         'Content-Type': 'application/json',
//       };

//       // First API call to get community IDs
//       final Uri profileUrl =
//           Uri.parse('${BASE_URL}api/showProfile?other=$userId');
//       final profileResponse = await http.get(profileUrl, headers: headers);

//       if (profileResponse.statusCode == 200) {
//         final profileData = json.decode(profileResponse.body);
//         final communityIds =
//             List<String>.from(profileData['result'][0]['communities'] ?? []);

//         if (communityIds.isEmpty) return [];

//         // Second API call to get community details
//         List<Community> fetchedCommunities = [];
//         for (String communityId in communityIds) {
//           final Uri communityUrl =
//               Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId');
//           final communityResponse =
//               await http.get(communityUrl, headers: headers);

//           if (communityResponse.statusCode == 200) {
//             final communityData = json.decode(communityResponse.body);
//             fetchedCommunities.add(Community.fromJson(communityData));
//           }
//         }
//         return fetchedCommunities;
//       } else {
//         print('Error: ${profileResponse.statusCode} - ${profileResponse.body}');
//         return [];
//       }
//     } catch (e) {
//       print('Error fetching communities: $e');
//       return [];
//     }
//   }

//   Future<void> updateCommunityCount(List<Community> communities) async {
//     if (mounted) {
//       setState(() {
//         communityCount = communities.length;
//       });
//     }
//   }

//   Widget _buildCommunitiesTab() {
//     if (isLoadingCommunities) {
//       return Center(
//         child: LoadingAnimationWidget.twistingDots(
//             leftDotColor: Theme.of(context).brightness == Brightness.dark
//                 ? AppColors.darkText
//                 : AppColors.lightText,
//             rightDotColor: Color(0xFF7400A5),
//             size: 20),
//       );
//     }

//     if (communities.isEmpty) {
//       return Center(
//         child: Text(
//           'No Communities Joined Yet',
//           style: GoogleFonts.roboto(
//             color: Theme.of(context).brightness == Brightness.dark
//                 ? Colors.white60
//                 : Colors.black54,
//             fontSize: 14,
//           ),
//         ),
//       );
//     }

//     return ListView.builder(
//       physics: const NeverScrollableScrollPhysics(),
//       shrinkWrap: true,
//       itemCount: communities.length,
//       itemBuilder: (context, index) {
//         final community = communities[index];

//         return Padding(
//           padding: EdgeInsets.only(left: 10.0.w, top: 10.h, right: 10.0.w),
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               color: Colors.transparent,
//               border: Border.all(
//                 color: Color(0xFF7400A5),
//               ),
//             ),
//             child: ListTile(
//               leading: CircleAvatar(
//                 radius: 24.r,
//                 backgroundColor: Color(0xFF7400A5),
//                 backgroundImage: community.profilePicture.isNotEmpty
//                     ? NetworkImage(community.profilePicture)
//                     : null,
//                 child: community.profilePicture.isEmpty
//                     ? Text(
//                         community.name.isNotEmpty
//                             ? community.name[0].toUpperCase()
//                             : '?',
//                         style: TextStyle(
//                           fontSize: 24.sp,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       )
//                     : null,
//               ),
//               title: Text(
//                 community.name,
//                 style: GoogleFonts.roboto(
//                   color: Color(0xFF7400A5),
//                   fontWeight: FontWeight.bold,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//               subtitle: Text(
//                 community.description ?? 'No description',
//                 style: GoogleFonts.roboto(color: Colors.grey),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               trailing: Text(
//                 '${communityMemberCounts[community.id] ?? 0} Members',
//                 style: GoogleFonts.roboto(
//                   color: Colors.grey,
//                   fontSize: 12.sp,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         CommunityDetailScreen(communityId: community.id),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProviderall>(context, listen: false);
//     return DefaultTabController(
//       length: 3,
//       child: SafeArea(
//         child: Scaffold(
//           backgroundColor: Theme.of(context).brightness == Brightness.dark
//               ? AppColors.lightText
//               : AppColors.darkText,
//           body: isprofileloaded
//               ? Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: Theme.of(context).brightness == Brightness.dark
//                             ? [
//                                 Colors.black,
//                                 Colors.black
//                               ]
//                             : AppColors.lightGradient),
//                   ),
//                   child: Column(
//                     children: [
//                       // AppBar equivalent
//                       Padding(
//                         padding: EdgeInsets.symmetric(
//                             horizontal: 8.w, vertical: 12.h),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.arrow_back_ios,
//                                   color: Theme.of(context).brightness ==
//                                           Brightness.dark
//                                       ? AppColors.darkText
//                                       : AppColors.lightText),
//                               onPressed: () => Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(
//                                       builder: (context) =>
//                                           BottomNavBarScreen())),
//                             ),
//                             Row(
//                               children: [
//                                 InkWell(
//                                   onTap: () {
//                                     print('lereeeeee bhaiii $privacychecker');
//                                   },
//                                   child: Container(
//                                     padding: EdgeInsets.symmetric(
//                                         horizontal: 8.w, vertical: 4.h),
//                                     child: Text(
//                                       privacychecker
//                                           ? 'Anonymous Mode On'
//                                           : 'Go Anonymous',
//                                       style: GoogleFonts.roboto(
//                                         fontSize: 14.sp,
//                                         color: Theme.of(context).brightness ==
//                                                 Brightness.dark
//                                             ? AppColors.darkText
//                                             : AppColors.lightText,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 5.w),
//                                 Padding(
//                                   padding: EdgeInsets.only(right: 30.w),
//                                   child: isloadingprivacy
//                                       ? GestureDetector(
//                                           onTap: () {
//                                             setState(() {
//                                               privacychecker = !privacychecker;
//                                             });

//                                             _updatePrivacyLevel(privacychecker)
//                                                 .then((_) {
//                                               if (mounted) {
//                                                 _rebuildScreen();
//                                               }
//                                             });
//                                           },
//                                           child: Container(
//                                             width: 60.w,
//                                             height: 30.h,
//                                             decoration: BoxDecoration(
//                                               borderRadius:
//                                                   BorderRadius.circular(20),
//                                               color: privacychecker
//                                                   ? Color(0xFF7400A5)
//                                                       .withOpacity(0.2)
//                                                   : Colors.grey.shade300,
//                                               border: Border.all(
//                                                 color: privacychecker
//                                                     ? Color(0xFF7400A5)
//                                                     : Colors.grey.shade400,
//                                                 width: 1.5,
//                                               ),
//                                             ),
//                                             child: Stack(
//                                               children: [
//                                                 AnimatedPositioned(
//                                                   duration: Duration(
//                                                       milliseconds: 200),
//                                                   curve: Curves.easeInOut,
//                                                   left: privacychecker ? 30 : 0,
//                                                   child: Container(
//                                                     width: 30.w,
//                                                     height: 30.h,
//                                                     decoration: BoxDecoration(
//                                                       shape: BoxShape.circle,
//                                                       color: privacychecker
//                                                           ? Color(0xFF7400A5)
//                                                           : Colors.white,
//                                                       boxShadow: [
//                                                         BoxShadow(
//                                                           color: Colors.black
//                                                               .withOpacity(0.1),
//                                                           blurRadius: 4,
//                                                           spreadRadius: 1,
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     child: Center(
//                                                       child: Icon(
//                                                         Icons
//                                                             .manage_accounts_rounded,
//                                                         size: 16,
//                                                         color: privacychecker
//                                                             ? Colors.white
//                                                             : Colors
//                                                                 .grey.shade600,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         )
//                                       : SizedBox(
//                                           height: 20.h,
//                                           width: 20.w,
//                                           child: CircularProgressIndicator(
//                                               strokeWidth: 2.0),
//                                         ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       // Main content in SingleChildScrollView
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 10.w),
//                             child: Column(
//                               children: [
//                                 SizedBox(height: 30),
//                                 Stack(
//                                   children: [
//                                     GestureDetector(
//                                       onTap: () {
//                                         if (userProvider.userId != null &&
//                                             userProvider.userToken != null &&
//                                             userProvider.userName != null) {
//                                           changeProfile(
//                                               context,
//                                               userProvider.userId!,
//                                               userProvider.userToken!,
//                                               userProvider.userName!);
//                                         }
//                                       },
//                                       child: Container(
//                                         height: 100.h,
//                                         width: 100.w,
//                                         child: CircleAvatar(
//                                           radius: 50,
//                                           backgroundImage:
//                                               getCurrentProfilePicture() != null
//                                                   ? NetworkImage(
//                                                       getCurrentProfilePicture()!)
//                                                   : null,
//                                           child:
//                                               getCurrentProfilePicture() == null
//                                                   ? SvgPicture.asset(
//                                                       'assets/icons/profile.svg',
//                                                       color: Colors.white,
//                                                       width: 70.w,
//                                                       height: 70.w,
//                                                     )
//                                                   : null,
//                                         ),
//                                       ),
//                                     ),
//                                     Positioned(
//                                       bottom: 0,
//                                       right: 0,
//                                       child: GestureDetector(
//                                         onTap: () {
//                                           Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       EditProfileScreen(
//                                                         avatar: avatar ?? '',
//                                                         selectedInterests:
//                                                             interests
//                                                                 .cast<String>(),
//                                                         onProfileUpdated: () {
//                                                           // Refresh the profile data
//                                                           _initializeProfile();
//                                                         },
//                                                       )));
//                                         },
//                                         child: Container(
//                                           padding: EdgeInsets.all(4),
//                                           decoration: BoxDecoration(
//                                             color: Colors.grey[700],
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: Icon(Icons.edit,
//                                               color: Colors.white, size: 20.sp),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 16),
//                                 Text(
//                                   Username ?? 'Loading...',
//                                   style: GoogleFonts.roboto(
//                                     color: Theme.of(context).brightness ==
//                                             Brightness.dark
//                                         ? AppColors.darkText
//                                         : AppColors.lightText,
//                                     fontSize: 24.sp,
//                                     fontWeight: FontWeight.w400,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4.h),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       bio,
//                                       textAlign: TextAlign.justify,
//                                       maxLines: isExpanded ? null : 2,
//                                       overflow: isExpanded
//                                           ? null
//                                           : TextOverflow.ellipsis,
//                                       style: GoogleFonts.roboto(
//                                         color: Theme.of(context).brightness ==
//                                                 Brightness.dark
//                                             ? AppColors.darkText
//                                             : AppColors.lightText,
//                                         fontWeight: FontWeight.w400,
//                                         fontSize: 16.sp,
//                                       ),
//                                     ),
//                                     if (bio.length > 100)
//                                       GestureDetector(
//                                         onTap: () {
//                                           setState(() {
//                                             isExpanded = !isExpanded;
//                                           });
//                                         },
//                                         child: Container(
//                                           margin: EdgeInsets.only(top: 8.h),
//                                           height: 30.h,
//                                           decoration: BoxDecoration(
//                                             color: Color(0xFF7400A5),
//                                             borderRadius:
//                                                 BorderRadius.circular(15.sp),
//                                             border: Border.all(
//                                               color: Color(0xFF7400A5),
//                                               width: 1,
//                                             ),
//                                           ),
//                                           child: Padding(
//                                             padding: EdgeInsets.symmetric(
//                                                 horizontal: 16.w,
//                                                 vertical: 4.h),
//                                             child: Text(
//                                               isExpanded
//                                                   ? 'Show Less'
//                                                   : 'Show More',
//                                               style: GoogleFonts.roboto(
//                                                 color: Colors.white,
//                                                 fontWeight: FontWeight.w500,
//                                                 fontSize: 12.sp,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 25.h),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     InkWell(
//                                         onTap: () {
//                                           Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       FollowerFollowingScreen(
//                                                         initialTabIndex: 0,
//                                                       )));
//                                         },
//                                         child: _buildStat(
//                                             'Followers', '$followers')),
//                                     SizedBox(width: 32),
//                                     InkWell(
//                                         onTap: () {
//                                           Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       FollowerFollowingScreen(
//                                                         initialTabIndex: 1,
//                                                       )));
//                                         },
//                                         child: _buildStat(
//                                             'Following', '$following')),
//                                     SizedBox(width: 25),
//                                     InkWell(
//                                         onTap: () {
//                                           Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       SettingsScreen(
//                                                         privacyLev:
//                                                             privacychecker,
//                                                       )));
//                                         },
//                                         child: Icon(Icons.settings, size: 28))
//                                   ],
//                                 ),
//                                 SizedBox(height: 20.h),
//                                 interests.isEmpty
//                                     ? SizedBox()
//                                     : Container(
//                                         padding: EdgeInsets.all(16),
//                                         decoration: BoxDecoration(
//                                           color: Color(0xFF2A2A3A),
//                                           borderRadius:
//                                               BorderRadius.circular(12),
//                                         ),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               'Interests',
//                                               style: GoogleFonts.roboto(
//                                                 color: Colors.white,
//                                                 fontSize: 18.sp,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                             SizedBox(height: 10),
//                                             Wrap(
//                                               spacing: 8.0,
//                                               runSpacing: 8.0,
//                                               children: [
//                                                 ...(!showAllInterests
//                                                         ? interests.take(3)
//                                                         : interests)
//                                                     .map((interest) {
//                                                   return Container(
//                                                     padding:
//                                                         EdgeInsets.symmetric(
//                                                             horizontal: 16.0,
//                                                             vertical: 8.0),
//                                                     decoration: BoxDecoration(
//                                                       color: Color(0xFF7400A5),
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               20),
//                                                     ),
//                                                     child: Text(
//                                                       interest,
//                                                       style: GoogleFonts.roboto(
//                                                         color: Colors.white,
//                                                         fontSize: 14.sp,
//                                                       ),
//                                                     ),
//                                                   );
//                                                 }).toList(),
//                                                 if (interests.length > 3)
//                                                   GestureDetector(
//                                                     onTap: () {
//                                                       setState(() {
//                                                         showAllInterests =
//                                                             !showAllInterests;
//                                                       });
//                                                     },
//                                                     child: Container(
//                                                       padding:
//                                                           EdgeInsets.symmetric(
//                                                               horizontal: 16.0,
//                                                               vertical: 8.0),
//                                                       decoration: BoxDecoration(
//                                                         color:
//                                                             Colors.transparent,
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(20),
//                                                       ),
//                                                       child: Text(
//                                                         showAllInterests
//                                                             ? 'Show Less'
//                                                             : 'Show +${interests.length - 3}',
//                                                         style:
//                                                             GoogleFonts.roboto(
//                                                           color: Colors.white,
//                                                           fontSize: 14.sp,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                 SizedBox(height: 15.h),
//                                 // TabContainer with dynamic height based on content
//                                 Container(
//                                   width: double.infinity,
//                                   child: DefaultTabController(
//                                     length: 3,
//                                     child: Column(
//                                      // mainAxisSize: MainAxisSize.min,
//                                       //crossAxisAlignment: CrossAxisAlignment.center,
//                                       children: [
//                                         TabBar(
//                                           tabAlignment: TabAlignment.center,
//                                           tabs: [
//                                             Tab(text: "Posts (${postsCount})"),
//                                             Tab(
//                                                 text:
//                                                     "Quotes (${quotesCount})"),
//                                             Tab(
//                                                 text:
//                                                     "Community (${communityCount})"),
//                                           ],
//                                           indicatorColor: Color(0xFF7400A5),
//                                           labelStyle: GoogleFonts.poppins(
//                                             color: Color(0xFF7400A5),
//                                           ),
//                                           unselectedLabelColor:
//                                               Theme.of(context).brightness ==
//                                                       Brightness.dark
//                                                   ? AppColors.darkText
//                                                   : AppColors.lightText,
//                                           unselectedLabelStyle:
//                                               GoogleFonts.poppins(
//                                             color:
//                                                 Theme.of(context).brightness ==
//                                                         Brightness.dark
//                                                     ? AppColors.darkText
//                                                     : AppColors.lightText,
//                                           ),
//                                           dividerColor: Colors.transparent,
//                                           padding: EdgeInsets.only(right: 12.0),
//                                           isScrollable: true,
//                                         ),
//                                         SizedBox(height: 10.h),
//                                         Builder(
//                                           builder: (BuildContext context) {
//                                             final TabController tabController =
//                                                 DefaultTabController.of(
//                                                     context)!;
//                                             return AnimatedBuilder(
//                                               animation: tabController,
//                                               builder: (context, _) {
//                                                 return Container(
//                                                   // Setting constraints but allowing content to determine final size
//                                                   constraints: BoxConstraints(
//                                                     // Set minimum dimensions to avoid layout issues
//                                                     minHeight: 100.h,
//                                                   ),
//                                                   child: tabController.index ==
//                                                           0
//                                                       ? _buildPostsTab()
//                                                       : tabController.index == 1
//                                                           ? _buildThoughtsTab()
//                                                           : _buildCommunitiesTab(),
//                                                 );
//                                               },
//                                             );
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : Center(
//                   child: LoadingAnimationWidget.twistingDots(
//                       leftDotColor:
//                           Theme.of(context).brightness == Brightness.dark
//                               ? AppColors.darkText
//                               : AppColors.lightText,
//                       rightDotColor: Color(0xFF7400A5),
//                       size: 20),
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStat(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//               color: Theme.of(context).brightness == Brightness.dark
//                   ? AppColors.darkText
//                   : AppColors.lightText,
//               fontSize: 15.sp,
//               fontWeight: FontWeight.w400),
//         ),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             color: Theme.of(context).brightness == Brightness.dark
//                 ? AppColors.darkText
//                 : AppColors.lightText,
//             fontSize: 16.sp,
//             fontWeight: FontWeight.w400,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTab(String text, {bool isSelected = false}) {
//     String displayText = text;

//     if (text == 'Posts') {
//       displayText = 'Posts (${postsCount})';
//     } else if (text == 'Quotes') {
//       displayText = 'Quotes ($quotesCount)';
//     } else if (text == 'Community') {
//       displayText = 'Community ($communityCount)';
//     }

//     return Column(
//       children: [
//         Text(
//           displayText,
//           style: GoogleFonts.roboto(
//               color: isSelected
//                   ? Theme.of(context).brightness == Brightness.dark
//                       ? Colors.yellow
//                       : AppColors.lightButton
//                   : Theme.of(context).brightness == Brightness.dark
//                       ? AppColors.darkText
//                       : AppColors.lightText,
//               fontSize: 14.sp,
//               fontWeight: FontWeight.w500),
//         ),
//         SizedBox(height: 4),
//         if (isSelected)
//           Container(
//               height: 2,
//               width: 40,
//               color: Theme.of(context).brightness == Brightness.dark
//                   ? Colors.yellow
//                   : AppColors.lightButton),
//       ],
//     );
//   }

//   Future<void> fetchCommunities() async {
//     setState(() {
//       isLoadingCommunities = true;
//     });

//     try {
//       final userId = Provider.of<UserProviderall>(context, listen: false).userId;
//       if (userId == null) {
//         setState(() {
//           isLoadingCommunities = false;
//         });
//         return;
//       }

//       final token = Provider.of<UserProviderall>(context, listen: false).userToken;
//       if (token == null) {
//         setState(() {
//           isLoadingCommunities = false;
//         });
//         return;
//       }

//       final headers = {
//         'token': token,
//         'userId': userId,
//         'Content-Type': 'application/json',
//       };

//       final Uri communitiesUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/user-communities');
//       final response = await http.get(
//         communitiesUrl,
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         final communityList = data['communities'] as List;
//         final fetchedCommunities = communityList
//             .map((communityJson) => Community.fromJson(communityJson))
//             .toList();

//         print("Fetched ${fetchedCommunities.length} communities");

//         if (mounted) {
//           setState(() {
//             communities = fetchedCommunities;
//             communityCount = fetchedCommunities.length;
//             isLoadingCommunities = false;
//           });
          
//           // Fetch member counts for each community
//           for (var community in communities) {
//             _fetchCommunityMemberCount(community.id);
//           }
//         }
//       } else {
//         print('Error fetching communities: ${response.statusCode} - ${response.body}');
//         if (mounted) {
//           setState(() {
//             isLoadingCommunities = false;
//           });
//         }
//       }
//     } catch (e) {
//       print('Error fetching communities: $e');
//       if (mounted) {
//         setState(() {
//           isLoadingCommunities = false;
//         });
//       }
//     }
//   }

//   // Add this new method to fetch member counts
//   Future<void> _fetchCommunityMemberCount(String communityId) async {
//     try {
//       final Uri communityUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId');
//       final userId = Provider.of<UserProviderall>(context, listen: false).userId ?? '';
//       final token = Provider.of<UserProviderall>(context, listen: false).userToken ?? '';

//       final headers = {
//         'token': token,
//         'userId': userId,
//         'Content-Type': 'application/json',
//       };

//       final communityResponse = await http.get(communityUrl, headers: headers);

//       if (communityResponse.statusCode == 200) {
//         final communityData = json.decode(communityResponse.body);
        
//         // Count members and update the state
//         if (communityData['members'] != null) {
//           final membersCount = (communityData['members'] as List).length;
//           if (mounted) {
//             setState(() {
//               communityMemberCounts[communityId] = membersCount;
//             });
//           }
//         }
//       } else {
//         print('Error fetching details for community $communityId: ${communityResponse.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching community member count: $e');
//     }
//   }

//   String? getCurrentProfilePicture() {
//     if (privacychecker) {
//       return avatar;
//     } else {
//       return profilepic?.isNotEmpty == true ? profilepic : avatar;
//     }
//   }

//   void _toggleBioExpansion() {
//     setState(() {
//       isExpanded = !isExpanded;
//     });
//   }
// }


import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/community/communityDetailedScreen.dart';
import 'package:socialmedia/community/communityListView.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/community/communityProvider.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/edit_profile.dart';
import 'package:socialmedia/users/searched_userprofile.dart' show VideoThumbnailWidget;
import 'package:socialmedia/users/settings.dart';
import 'package:socialmedia/users/show_post_content.dart';
import 'package:socialmedia/users/userfollowinglist.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:switcher_button/switcher_button.dart';
import 'package:tab_container/tab_container.dart';
import 'package:video_player/video_player.dart';

class user_profile extends StatefulWidget {
  const user_profile({
    super.key,
  });

  @override
  State<user_profile> createState() => _user_profileState();
}

class _user_profileState extends State<user_profile> with TickerProviderStateMixin {
  String? Username;
  String? nickname;
  List<Map<String, dynamic>> posts = []; // State to hold the posts
  String? selectedImageUrl; // State to track the selected image for preview
  String? selectedImageContent;
  int followers = 0;
  int following = 0;
  int postlength = 0;
  bool isLoadingpost = true;
  bool privacychecker = false;
  bool isloadingprivacy = false;
  bool isprofileloaded = false;
  String? profilepic;
  String? referralCode;
  int? referralCount;
  bool isonpost = true;
  String bio = '';
  late UserProviderall userProvider;
  List<dynamic> interests = [];
  bool showAllInterests = false;
  bool isExpanded = false;
  bool _showReadMore = false;
  int communityCount = 0;
  List<Community> communities = [];
  bool isLoadingCommunities = true;
  late TabController _tabController;
  int _currentTabIndex = 0;
  String? avatar;
  Map<String, int> communityMemberCounts = {};

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;

        // Fetch communities when the community tab is selected
        if (_currentTabIndex == 2) {
          fetchCommunities();
        }
      });
    });

    // Fetch communities initially
    fetchCommunities();
  }

  int get postsCount => posts.where((post) => post['data']['media'] != null && post['data']['media'].isNotEmpty).length;
  int get quotesCount => posts.where((post) => post['data']['media'] == null || post['data']['media'].isEmpty).length;
  // int get communityCount => 0;

  Future<void> _initializeProfile() async {
    if (!mounted) return;

    userProvider = Provider.of<UserProviderall>(context, listen: false);
    await userProvider.loadUserData();

    if (!mounted) return;

    await fetchProfile();
    await fetchPosts();

    if (!mounted) return;

    setState(() {
      isprofileloaded = true;
    });
  }

  Future<void> _loadPrivacyState() async {
    final prefs = await SharedPreferences.getInstance();
  }

  Future<void> _savePrivacyState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_switch_value', value);
  }

  void _rebuildScreen() {
    _initializeProfile();
  }

  Future<void> changeProfile(BuildContext context, String userId, String token, String name) async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedFile;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(
                  'Take A Photo',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () async {
                  pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context);
                  if (pickedFile != null) {
                    uploadImage(File(pickedFile!.path), userId, token, name);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Choose From Gallery', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () async {
                  pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context);
                  if (pickedFile != null) {
                    uploadImage(File(pickedFile!.path), userId, token, name);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text('Delete Profile Pic', style: GoogleFonts.poppins(fontSize: 14, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7400A5),
                        ),
                      );
                    },
                  );

                  try {
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    final String? userId = prefs.getString('user_id');
                    final String? token = prefs.getString('user_token');

                    if (userId == null || token == null) {
                      throw Exception('User ID or token is missing');
                    }

                    final response = await http.delete(
                      Uri.parse('${BASE_URL}api/profile-picture'),
                      headers: {
                        'userId': userId,
                        'token': token,
                      },
                    );

                    Navigator.pop(context);

                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Center(
                            child: Text(
                              'Profile picture deleted successfully',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const user_profile()));
                    } else {
                      throw Exception('Failed to delete profile picture: ${response.body}');
                    }
                  } catch (e) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            'Error: ${e.toString()}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> uploadImage(dynamic imageFile, String userId, String token, String name) async {
    var uri = Uri.parse("${BASE_URL}api/edit-profile");

    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll({
        'userId': userId,
        'token': token,
      });

    if (imageFile is File) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    } else if (imageFile is String && imageFile.isEmpty) {
      request.fields['image'] = '';
    }

    request.fields['name'] = name;

    var response = await request.send();
    var responseString = await response.stream.bytesToString();

    print("Status Code: ${response.statusCode}");
    print("Response: $responseString");

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const user_profile()));
      print("Image uploaded successfully");
    } else {
      print("Failed to upload image");
    }
  }

  Future<void> _updatePrivacyLevel(bool value) async {
      // Immediately update the UI state
      setState(() {
        privacychecker = value;
        if (value) {
          Username = nickname;
        } else {
          Username = profileData?['name'];
        }
      });

      // Update the user provider
      if (mounted) {
        final userProvider = Provider.of<UserProviderall>(context, listen: false);
        userProvider.updatePrivacyState(value);
        userProvider.updateProfilePic(profilepic);
        userProvider.updateAvatar(avatar);
      }

      // Make API call in background
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token') ?? '';
        final userId = prefs.getString('user_id') ?? '';

        // Create the multipart request
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('${BASE_URL}api/edit-profile'),
        );

        // Add headers
        request.headers['token'] = token;
        request.headers['userId'] = userId;

        // Add form fields
        request.fields['privacyLevel'] = value ? '1' : '0';

        // Send the request
        final response = await request.send();

        // Get the response
        final responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          await _savePrivacyState(value);
        } else {
          // If API call fails, revert the state
          if (mounted) {
            setState(() {
              privacychecker = !value;
              if (!value) {
                Username = nickname;
              } else {
                Username = profileData?['name'];
              }
            });
            // Also revert the provider state
            final userProvider = Provider.of<UserProviderall>(context, listen: false);
            userProvider.updatePrivacyState(!value);
            userProvider.updateProfilePic(profilepic);
            userProvider.updateAvatar(avatar);
          }
          throw Exception('Failed to update privacy level: $responseData');
        }
      } catch (e) {
        print("Error updating privacy level: $e");
        // State is already reverted if needed
        rethrow;
      }
    }

  Future<void> fetchPosts() async {
    final String url = '${BASE_URL}api/get-posts';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text('User ID or Token is missing.'))),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'userid': userid,
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<Map<String, dynamic>> allPosts = List<Map<String, dynamic>>.from(data['posts']);
        final List<Map<String, dynamic>> mediaOnlyPosts = allPosts.where((post) => post['data']['media'] != null && post['data']['media'].isNotEmpty).toList();

        setState(() {
          posts = allPosts;
          posts.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          isLoadingpost = false;
        });
      } else {
        print('Failed to fetch posts: ${response.statusCode}');
        setState(() {
          isLoadingpost = false;
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text('An error occurred while fetching posts.'))),
      );
      setState(() {
        isLoadingpost = false;
      });
    }
  }

  Map<String, dynamic>? profileData;
  bool isLoading = false;

  Future<void> fetchProfile() async {
    if (!mounted) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      print('User ID or token is missing');
      return;
    }

    final Uri url = Uri.parse('${BASE_URL}api/showProfile?other=$userid');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'userid': userid,
      'token': token,
    };

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final http.Response response = await http.get(url, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['result'] != null && responseData['result'] is List && responseData['result'].isNotEmpty) {
          final userDetails = responseData['result'][0];

          log('User Details: ${jsonEncode(userDetails)}', name: 'User Details');

          if (!mounted) return;

          setState(() {
            followers = userDetails['followers'] ?? 0;
            following = userDetails['followings'] ?? 0;
            Username = userDetails['name'];
            nickname = userDetails['nickName'] ?? 'Delta';
            profileData = userDetails;
            privacychecker = userDetails['privacyLevel'] == "1" ? true : false;
            isloadingprivacy = true;
            profilepic = userDetails['profilePic'];
            referralCode = userDetails['referralCode'];
            referralCount = userDetails['referralData']["referralCount"];
            avatar = userDetails['avatar'];
            final int public = userDetails['public'] ?? 1;
            userProvider.setPublicStatus(public);
            bio = userDetails['bio'];
            interests = userDetails['interests'] ?? [];

            if (privacychecker) {
              Username = nickname;
            } else {
              Username = userDetails['name'];
            }
          });
        }
      }
    } catch (error) {
      print('An error occurred: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showImagePreview(String imageUrl, String content) {
    setState(() {
      selectedImageUrl = imageUrl;
      selectedImageContent = content;
    });
  }

  void _closeImagePreview() {
    setState(() {
      selectedImageUrl = null;
    });
  }

  Widget _buildPostsTab() {
    final mediaPosts = posts.where((post) {
      final data = post['data'] as Map<String, dynamic>?;
      final media = data?['media'] as List<dynamic>?;
      return media != null && media.isNotEmpty;
    }).toList();

    if (isLoadingpost || mediaPosts.isEmpty) {
      return Center(
        child: Text(
          'No Posts to show',
          style: GoogleFonts.roboto(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    // GridView that will be part of the main scroll
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      physics: const NeverScrollableScrollPhysics(), // disable inner scroll
      shrinkWrap: true, // essential to calculate proper height
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 2,
      ),
      itemCount: mediaPosts.length,
      itemBuilder: (context, index) {
        final post = mediaPosts[index];
        final data = post['data'] as Map<String, dynamic>?;
        final mediaList = data?['media'] as List<dynamic>?;

        String mediaUrl = '';
        if (mediaList != null && mediaList.isNotEmpty) {
          final firstMedia = mediaList[0] as Map<String, dynamic>?;
          mediaUrl = firstMedia?['url'] as String? ?? '';
        }

        final bool isVideo = mediaUrl.toLowerCase().endsWith('.mp4') || mediaUrl.toLowerCase().endsWith('.mov') || mediaUrl.toLowerCase().endsWith('.webm') || mediaUrl.toLowerCase().contains('video');

        return GestureDetector(
          onTap: () {
            final feedId = post['feedId'] as String?;
            if (feedId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailsScreen(feedId: feedId),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.sp),
              child: isVideo
                  ? Stack(
                      children: [
                        VideoThumbnailWidget(videoUrl: mediaUrl),
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 28,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    )
                  : Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThoughtsTab() {
    final thoughtPosts = posts.where((post) {
      final data = post['data'] as Map<String, dynamic>?;
      final media = data?['media'] as List<dynamic>?;
      return media == null || media.isEmpty;
    }).toList();

    return Container(
      child: isLoadingpost
          ? Center(
              child: Text(
                'Loading thoughts...',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          : thoughtPosts.isEmpty
              ? Center(
                  child: Text(
                    'No Quotes To Show',
                    style: GoogleFonts.roboto(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: thoughtPosts.length,
                  itemBuilder: (context, index) {
                    final post = thoughtPosts[index];
                    final data = post['data'] as Map<String, dynamic>?;
                    final content = data?['content'] ?? 'No content';
                    final createdAt = post['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(post['createdAt'] * 1000) : null;
                    final formattedDate = createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : '';
                    final profilePic = post['profilePic'] as String? ?? '';
                    final name = post['name'] as String? ?? 'Unknown';

                    return GestureDetector(
                      onTap: () {
                        final feedId = post['feedId'] as String?;
                        if (feedId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailsScreen(feedId: feedId),
                            ),
                          );
                        }
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color(0xFF2A2A3A),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(privacychecker ? post['avatar'] as String? ?? '' : post['profilePic'] as String? ?? ''),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    name,
                                    style: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                content,
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.favorite_border, color: Colors.grey, size: 18.sp),
                                  const SizedBox(width: 4),
                                  Text(
                                    (post['reactionCount'] as int? ?? 0).toString(),
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18.sp),
                                  const SizedBox(width: 4),
                                  Text(
                                    (post['commentCount'] as int? ?? 0).toString(),
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildCommunitiesTab() {
    if (isLoadingCommunities) {
      return Center(
        child: LoadingAnimationWidget.twistingDots(leftDotColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, rightDotColor: const Color(0xFF7400A5), size: 20),
      );
    }

    if (communities.isEmpty) {
      return Center(
        child: Text(
          'No Communities Joined Yet',
          style: GoogleFonts.roboto(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];

        return Padding(
          padding: EdgeInsets.only(left: 10.0.w, top: 10.h, right: 10.0.w),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              border: Border.all(
                color: const Color(0xFF7400A5),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24.r,
                backgroundColor: const Color(0xFF7400A5),
                backgroundImage: community.profilePicture.isNotEmpty ? NetworkImage(community.profilePicture) : null,
                child: community.profilePicture.isEmpty
                    ? Text(
                        community.name.isNotEmpty ? community.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              title: Text(
                community.name,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF7400A5),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                community.description ?? 'No description',
                style: GoogleFonts.roboto(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${communityMemberCounts[community.id] ?? 0} Members',
                style: GoogleFonts.roboto(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityDetailScreen(communityId: community.id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
          body: isprofileloaded
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                Colors.black,
                                Colors.black
                              ]
                            : AppColors.lightGradient),
                  ),
                  child: Column(
                    children: [
                      // AppBar equivalent
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BottomNavBarScreen())),
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    print('lereeeeee bhaiii $privacychecker');
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    child: Text(
                                      privacychecker ? 'Anonymous Mode On' : 'Go Anonymous',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14.sp,
                                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Padding(
                                  padding: EdgeInsets.only(right: 30.w),
                                  child: isloadingprivacy
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              privacychecker = !privacychecker;
                                            });

                                            _updatePrivacyLevel(privacychecker).then((_) {
                                              if (mounted) {
                                                _rebuildScreen();
                                              }
                                            });
                                          },
                                          child: Container(
                                            width: 60.w,
                                            height: 30.h,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              color: privacychecker ? const Color(0xFF7400A5).withOpacity(0.2) : Colors.grey.shade300,
                                              border: Border.all(
                                                color: privacychecker ? const Color(0xFF7400A5) : Colors.grey.shade400,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                AnimatedPositioned(
                                                  duration: const Duration(milliseconds: 200),
                                                  curve: Curves.easeInOut,
                                                  left: privacychecker ? 30 : 0,
                                                  child: Container(
                                                    width: 30.w,
                                                    height: 30.h,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: privacychecker ? const Color(0xFF7400A5) : Colors.white,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.1),
                                                          blurRadius: 4,
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.manage_accounts_rounded,
                                                        size: 16,
                                                        color: privacychecker ? Colors.white : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          height: 20.h,
                                          width: 20.w,
                                          child: const CircularProgressIndicator(strokeWidth: 2.0),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Main content in SingleChildScrollView
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Column(
                              children: [
                                const SizedBox(height: 30),
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (userProvider.userId != null && userProvider.userToken != null && userProvider.userName != null) {
                                          changeProfile(context, userProvider.userId!, userProvider.userToken!, userProvider.userName!);
                                        }
                                      },
                                      child: Container(
                                        height: 100.h,
                                        width: 100.w,
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundImage: getCurrentProfilePicture() != null ? NetworkImage(getCurrentProfilePicture()!) : null,
                                          child: getCurrentProfilePicture() == null
                                              ? SvgPicture.asset(
                                                  'assets/icons/profile.svg',
                                                  color: Colors.white,
                                                  width: 70.w,
                                                  height: 70.w,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => EditProfileScreen(
                                                        avatar: avatar ?? '',
                                                        selectedInterests: interests.cast<String>(),
                                                        onProfileUpdated: () {
                                                          // Refresh the profile data
                                                          _initializeProfile();
                                                        },
                                                      )));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[700],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.edit, color: Colors.white, size: 20.sp),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  Username ?? 'Loading...',
                                  style: GoogleFonts.roboto(
                                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bio,
                                      textAlign: TextAlign.justify,
                                      maxLines: isExpanded ? null : 5,
                                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    if (bio.length > 100)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isExpanded = !isExpanded;
                                          });
                                        },
                                        child: Container(
                                          height: 30.h,
                                          decoration: BoxDecoration(
                                              color: const Color(0xFF7400A5),
                                              borderRadius: BorderRadius.circular(15.sp),
                                              border: Border.all(
                                                color: const Color(0xFF7400A5),
                                                width: 1,
                                              )),
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0.h),
                                            child: Text(
                                              isExpanded ? 'Show Less' : 'Show More',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 25.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => const FollowerFollowingScreen(
                                                        initialTabIndex: 0,
                                                      )));
                                        },
                                        child: _buildStat('Followers', '$followers')),
                                    const SizedBox(width: 32),
                                    InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => const FollowerFollowingScreen(
                                                        initialTabIndex: 1,
                                                      )));
                                        },
                                        child: _buildStat('Following', '$following')),
                                    const SizedBox(width: 25),
                                    InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => SettingsScreen(
                                                        privacyLev: privacychecker,
                                                        referralCode: referralCode,
                                                        refferCount: referralCount,
                                                      )));
                                        },
                                        child: const Icon(Icons.settings, size: 28))
                                  ],
                                ),
                                
                                SizedBox(height: 20.h),
                                
                                interests.isEmpty
                                    ? const SizedBox()
                                    : Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2A2A3A),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Interests',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white,
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8.0,
                                              runSpacing: 8.0,
                                              children: [
                                                ...(!showAllInterests ? interests.take(3) : interests).map((interest) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF7400A5),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      interest,
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.white,
                                                        fontSize: 14.sp,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                if (interests.length > 3)
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        showAllInterests = !showAllInterests;
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.transparent,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        showAllInterests ? 'Show Less' : 'Show +${interests.length - 3}',
                                                        style: GoogleFonts.roboto(
                                                          color: Colors.white,
                                                          fontSize: 14.sp,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                SizedBox(height: 15.h),
                                // TabContainer with dynamic height based on content
                                Container(
                                  width: double.infinity,
                                  child: DefaultTabController(
                                    length: 3,
                                    child: Column(
                                      // mainAxisSize: MainAxisSize.min,
                                      //crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        TabBar(
                                          tabAlignment: TabAlignment.center,
                                          tabs: [
                                            Tab(text: "Posts (${postsCount})"),
                                            Tab(text: "Quotes (${quotesCount})"),
                                            Tab(text: "Community (${communityCount})"),
                                          ],
                                          indicatorColor: const Color(0xFF7400A5),
                                          labelStyle: GoogleFonts.poppins(
                                            color: const Color(0xFF7400A5),
                                          ),
                                          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                          unselectedLabelStyle: GoogleFonts.poppins(
                                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                          ),
                                          dividerColor: Colors.transparent,
                                          padding: const EdgeInsets.only(right: 12.0),
                                          isScrollable: true,
                                        ),
                                        SizedBox(height: 10.h),
                                        Builder(
                                          builder: (BuildContext context) {
                                            final TabController tabController = DefaultTabController.of(context)!;
                                            return AnimatedBuilder(
                                              animation: tabController,
                                              builder: (context, _) {
                                                return Container(
                                                  // Setting constraints but allowing content to determine final size
                                                  constraints: BoxConstraints(
                                                    // Set minimum dimensions to avoid layout issues
                                                    minHeight: 100.h,
                                                  ),
                                                  child: tabController.index == 0
                                                      ? _buildPostsTab()
                                                      : tabController.index == 1
                                                          ? _buildThoughtsTab()
                                                          : _buildCommunitiesTab(),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: LoadingAnimationWidget.twistingDots(leftDotColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, rightDotColor: const Color(0xFF7400A5), size: 20),
                ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 15.sp, fontWeight: FontWeight.w400),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String text, {bool isSelected = false}) {
    String displayText = text;

    if (text == 'Posts') {
      displayText = 'Posts (${postsCount})';
    } else if (text == 'Quotes') {
      displayText = 'Quotes ($quotesCount)';
    } else if (text == 'Community') {
      displayText = 'Community ($communityCount)';
    }

    return Column(
      children: [
        Text(
          displayText,
          style: GoogleFonts.roboto(
              color: isSelected
                  ? Theme.of(context).brightness == Brightness.dark
                      ? Colors.yellow
                      : AppColors.lightButton
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText
                      : AppColors.lightText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        if (isSelected) Container(height: 2, width: 40, color: Theme.of(context).brightness == Brightness.dark ? Colors.yellow : AppColors.lightButton),
      ],
    );
  }

  Future<void> fetchCommunities() async {
    setState(() {
      isLoadingCommunities = true;
    });

    try {
      final userId = Provider.of<UserProviderall>(context, listen: false).userId;
      if (userId == null) {
        setState(() {
          isLoadingCommunities = false;
        });
        return;
      }

      final token = Provider.of<UserProviderall>(context, listen: false).userToken;
      if (token == null) {
        setState(() {
          isLoadingCommunities = false;
        });
        return;
      }

      final headers = {
        'token': token,
        'userId': userId,
        'Content-Type': 'application/json',
      };

      final Uri communitiesUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/user-communities');
      final response = await http.get(
        communitiesUrl,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final communityList = data['communities'] as List;
        final fetchedCommunities = communityList.map((communityJson) => Community.fromJson(communityJson)).toList();

        print("Fetched ${fetchedCommunities.length} communities");

        if (mounted) {
          setState(() {
            communities = fetchedCommunities;
            communityCount = fetchedCommunities.length;
            isLoadingCommunities = false;
          });

          // Fetch member counts for each community
          for (var community in communities) {
            _fetchCommunityMemberCount(community.id);
          }
        }
      } else {
        print('Error fetching communities: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            isLoadingCommunities = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching communities: $e');
      if (mounted) {
        setState(() {
          isLoadingCommunities = false;
        });
      }
    }
  }

  // Add this new method to fetch member counts
  Future<void> _fetchCommunityMemberCount(String communityId) async {
    try {
      final Uri communityUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId');
      final userId = Provider.of<UserProviderall>(context, listen: false).userId ?? '';
      final token = Provider.of<UserProviderall>(context, listen: false).userToken ?? '';

      final headers = {
        'token': token,
        'userId': userId,
        'Content-Type': 'application/json',
      };

      final communityResponse = await http.get(communityUrl, headers: headers);

      if (communityResponse.statusCode == 200) {
        final communityData = json.decode(communityResponse.body);

        // Count members and update the state
        if (communityData['members'] != null) {
          final membersCount = (communityData['members'] as List).length;
          if (mounted) {
            setState(() {
              communityMemberCounts[communityId] = membersCount;
            });
          }
        }
      } else {
        print('Error fetching details for community $communityId: ${communityResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching community member count: $e');
    }
  }

  String? getCurrentProfilePicture() {
    if (privacychecker) {
      return avatar;
    } else {
      return profilepic?.isNotEmpty == true ? profilepic : avatar;
    }
  }
}
