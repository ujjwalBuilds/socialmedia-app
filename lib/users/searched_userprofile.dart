import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/detailed_chat_page.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/community/communityDetailedScreen.dart';
import 'package:socialmedia/community/communityListView.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/community/searchedUserCommunityList.dart';
import 'package:socialmedia/user_apis/acceptrequest.dart';
import 'package:socialmedia/users/show_post_content.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:story_view/story_view.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId; // ID of the profile we're viewing

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  List<dynamic> _posts = [];
  Map<String, List<dynamic>>? _stories;
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  String? _error;
  String? user__Id;
  String? __token;
  late TabController _tabController;
  int _currentTabIndex = 0;
  late UserProviderall userProvider;
  List<dynamic> interests = [];
  bool showAllInterests = false;
  int communityCount = 0;
  List<Community> communities = [];
  bool isLoadingCommunities = true;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {}); // Refresh UI after loading data
    });
    _loadPreferences();
    initializeApiServiceAndLoadProfile();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    fetchCommunities();
  }

  void _toggleBioExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  int get postsCount => _posts
      .where((post) =>
          post['data']['media'] != null && post['data']['media'].isNotEmpty)
      .length;
  int get quotesCount => _posts
      .where((post) =>
          post['data']['media'] == null || post['data']['media'].isEmpty)
      .length;
  //  get communityCount => communities.length;

  Future<void> blockUser(BuildContext context, String blockedUserId) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    final url = Uri.parse('${BASE_URL}api/block-user');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'userid': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
        },
        body: jsonEncode({'blocked': blockedUserId}),
      );

      if (response.statusCode == 200) {
        debugPrint('User blocked successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('User blocked',
                  style: TextStyle(fontFamily: 'Poppins'))),
        );
      } else {
        debugPrint('Failed to block user: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to block user',
                  style: TextStyle(fontFamily: 'Poppins'))),
        );
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Something went wrong',
                style: TextStyle(fontFamily: 'Poppins'))),
      );
    }
  }

  Future<void> _startChat(String participantId) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/start-message'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
        },
        body: json.encode({
          'userId2': participantId,
        }),
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final chatRoom = ChatRoom.fromJson(jsonResponse['chatRoom']);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DChatScreen(chatRoom: chatRoom)));
      } else {
        throw Exception('Failed to start chat');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        'Error starting chat: ${e.toString()}',
        style: GoogleFonts.roboto(),
      )));
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      user__Id = prefs.getString('user_id'); // Fetch userId
      __token = prefs.getString('user_token'); // Fetch token
    });
  }

  Future<void> initializeApiServiceAndLoadProfile() async {
    try {
      await _apiService.initialize();
      await _loadProfile();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> sendFriendRequest(String userId, BuildContext context) async {
    try {
      // Show loading indicator while sending the request
      setState(() {
        _isLoading = true;
      });

      // Make the POST request to send a friend request
      final response = await _apiService.makeRequest(
        path: 'api/sendRequest',
        method: 'POST',
        body: {
          'sentTo': userId, // Pass the userId of the profile being viewed
        },
      );

      // Handle successful response
      if (response['message'] != null) {
        Fluttertoast.showToast(
          msg: "Request Sent",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER, // 👈 Display in the center
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      // Handle errors
      Fluttertoast.showToast(
        msg: "Already Sent",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER, // 👈 Display in the center
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      await _apiService.initialize();
      final response = await _apiService.makeRequest(
        path: 'api/showProfile?other=${widget.userId}',
        method: 'GET',
      );

      setState(() {
        _profileData = response['result'][0];
        interests = _profileData!['interests'] ?? [];
        _isLoading = false;
      });
      print(interests);

      if (_profileData?['public'] == 1) {
        _loadPosts();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final response = await _apiService.makeRequest(
        path: 'api/get-posts?userId=${widget.userId}',
        method: 'GET',
      );
      setState(() {
        _posts = List<dynamic>.from(response['posts']);
        print('hullulululu $_posts');
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadStories() async {
    try {
      final response = await _apiService.makeRequest(
        path: 'api/get-story-for-user',
        method: 'GET',
      );
      if (response['stories'] != null) {
        setState(() {
          _stories = Map<String, List<dynamic>>.from(response['stories']);
        });
        _showStories();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Center(child: Text('Failed to load stories: ${e.toString()}'))),
      );
    }
  }

  Future<List<Community>> fetchUserCommunities(
      String userId, UserProviderall userProvider) async {
    try {
      final token = userProvider.userToken;

      if (token == null) {
        return [];
      }

      // Set headers with authorization token
      final headers = {
        'token': token,
        'userId': userId,
        'Content-Type': 'application/json',
      };

      // Make API call to fetch user communities
      final Uri communitiesUrl =
          Uri.parse('${BASE_URL_COMMUNITIES}api/communities/user-communities');
      final response = await http.get(
        communitiesUrl,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the communities from the response
        final communityList = data['communities'] as List;
        return communityList
            .map((communityJson) => Community.fromJson(communityJson))
            .toList();
      } else {
        print(
            'Error fetching communities: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching communities: $e');
      return [];
    }
  }

  Future<void> fetchCommunities() async {
    setState(() {
      isLoadingCommunities = true;
    });

    try {
      final communities =
          await fetchUserCommunities(widget.userId, userProvider);

      if (mounted) {
        setState(() {
          this.communities = communities;
          communityCount = communities.length;
          isLoadingCommunities = false;
        });
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

  void _showStories() {
    if (_stories == null || !_stories!.containsKey(widget.userId)) return;

    final storyItems = _stories![widget.userId]!.map((story) {
      return StoryItem.pageImage(
        url: story['url'],
        caption: story['ago_time'],
        controller: StoryController(),
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryView(
          storyItems: storyItems,
          controller: StoryController(),
          onComplete: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showProfilePhotoDialog(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
              // Profile photo
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF7400A5), width: 3),
                ),
                child: ClipOval(
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child:
                            Icon(Icons.person, size: 100, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildHeader() {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 16.w),
  //     child: Column(
  //       children: [
  //         SizedBox(height: 16.h),
  //         CustomProfileAvatar(
  //           profilePicUrl: _profileData!['profilePic'],
  //           matchScore: _profileData!['compatibility'] ?? "0",
  //           avatar: _profileData!['avatar'],
  //           onTap: (photoUrl) {
  //             _showProfilePhotoDialog(photoUrl);
  //           },
  //         ),
  //         SizedBox(height: 16.h),
  //         Text(
  //           _profileData?['name'] ?? '',
  //           style: GoogleFonts.roboto(
  //             color: Theme.of(context).brightness == Brightness.dark
  //                 ? AppColors.darkText
  //                 : AppColors.lightText,
  //             fontSize: 20.sp,
  //             fontWeight: FontWeight.w400,
  //           ),
  //           textAlign: TextAlign.center,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //         SizedBox(height: 8.h),
  //         if (_profileData?['bio'] != null && _profileData!['bio'].isNotEmpty)
  //           Column(
  //             children: [
  //               Text(
  //                 _profileData!['bio'],
  //                 style: GoogleFonts.roboto(
  //                   color: Theme.of(context).brightness == Brightness.dark
  //                       ? Colors.grey[300]
  //                       : Colors.grey[700],
  //                   fontSize: 14.sp,
  //                 ),
  //                 maxLines: isExpanded ? null : 2,
  //                 overflow: isExpanded ? null : TextOverflow.ellipsis,
  //               ),
  //               if (_profileData!['bio'].length > 100)
  //                 GestureDetector(
  //                   onTap: _toggleBioExpansion,
  //                   child: Container(
  //                     margin: EdgeInsets.only(top: 8.h),
  //                     height: 30.h,
  //                     decoration: BoxDecoration(
  //                       color: Color(0xFF7400A5),
  //                       borderRadius: BorderRadius.circular(15.sp),
  //                       border: Border.all(
  //                         color: Color(0xFF7400A5),
  //                         width: 1,
  //                       ),
  //                     ),
  //                     child: Padding(
  //                       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
  //                       child: Text(
  //                         isExpanded ? 'Show Less' : 'Show More',
  //                         style: GoogleFonts.roboto(
  //                           color: Colors.white,
  //                           fontWeight: FontWeight.w500,
  //                           fontSize: 12.sp,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         SizedBox(height: 16.h),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Expanded(
  //               child: Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 4.w),
  //                 child: ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor:
  //                         Theme.of(context).brightness == Brightness.dark
  //                             ? Colors.transparent
  //                             : Colors.white,
  //                     foregroundColor: Colors.white,
  //                     minimumSize: Size(0, 34.h),
  //                     side: BorderSide(
  //                       color: Color(0xFF7400A5),
  //                     ),
  //                   ),
  //                   onPressed: () {
  //                     if (_profileData?['isFollowing'] == true) {
  //                       _startChat(widget.userId);
  //                     } else {
  //                       Fluttertoast.showToast(
  //                         msg: "You need to follow this user to message them",
  //                         toastLength: Toast.LENGTH_SHORT,
  //                         gravity: ToastGravity.CENTER,
  //                         backgroundColor: Colors.black87,
  //                         textColor: Colors.white,
  //                         fontSize: 16.0,
  //                       );
  //                     }
  //                   },
  //                   child: Text(
  //                     'Message',
  //                     style: GoogleFonts.poppins(
  //                       color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
  //                       fontSize: 12.sp,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             SizedBox(width: 8.w),
  //             Expanded(
  //               child: Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 4.w),
  //                 child: ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Color(0xFF7400A5),
  //                     foregroundColor: Colors.white,
  //                     minimumSize: Size(0, 34.h),
  //                   ),
  //                   onPressed: () async {
  //                     print('yele 1');
  //                     if (_profileData?['requestSent'] == true) return;

  //                     // Case 2: User is already following - handle unfollow
  //                     print('yele 2');

  //                     if (_profileData?['requestPending'] == true) {
  //                       try {
  //                         final response = await http.put(
  //                           Uri.parse("${BASE_URL}api/acceptRequest"),
  //                           headers: {
  //                             'userid': userProvider.userId ?? '',
  //                             'token': userProvider.userToken ?? '',
  //                             "Content-Type": "application/json",
  //                           },
  //                           body: jsonEncode({
  //                             "otherId": widget.userId,
  //                           }),
  //                         );

  //                         if (response.statusCode == 200) {
  //                           setState(() {
  //                             _profileData?['requestPending'] = false;
  //                           });
  //                           Fluttertoast.showToast(
  //                             msg: "Request accepted successfully",
  //                             toastLength: Toast.LENGTH_SHORT,
  //                           );
  //                           _loadPosts(); // Reload posts since user is now following
  //                         }
  //                       } catch (e) {
  //                         print("Error accepting request: $e");
  //                         Fluttertoast.showToast(
  //                           msg: "Failed to accept request",
  //                           toastLength: Toast.LENGTH_SHORT,
  //                         );
  //                       }
  //                       return;
  //                     }

  //                     if (_profileData?['isFollowing'] == true) {
  //                       return;
  //                     }

  //                     print('yee;ele 2.5');

  //                     print('yele 3');

  //                     // Case 3: Handle pending request (Accept)

  //                     // Case 4: Handle follow back (user is a follower but not following)
  //                     print('yele 4');

  //                     // Case 5: Default case - Send friend request
  //                     try {
  //                       final response = await http.post(
  //                         Uri.parse("${BASE_URL}api/sendRequest"),
  //                         headers: {
  //                           'userId': userProvider.userId ?? '',
  //                           'token': userProvider.userToken ?? '',
  //                           "Content-Type": "application/json",
  //                         },
  //                         body: jsonEncode({
  //                           "sentTo": widget.userId, // Pass otherId as JSON
  //                         }),
  //                       );

  //                       if (response.statusCode == 200) {
  //                         setState(() {
  //                           _profileData?['requestSent'] = true;
  //                         });
  //                         Fluttertoast.showToast(
  //                           msg: "Friend request sent",
  //                           toastLength: Toast.LENGTH_SHORT,
  //                         );
  //                       }
  //                     } catch (e) {
  //                       print("Error sending friend request: $e");
  //                       Fluttertoast.showToast(
  //                         msg: "Failed to send friend request",
  //                         toastLength: Toast.LENGTH_SHORT,
  //                       );
  //                     }
  //                   },
  //                   child: Text(
  //                     _getButtonText(),
  //                     style: GoogleFonts.poppins(
  //                       color: Colors.white,
  //                       fontSize: 12.sp,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 16.h),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             _buildStatColumn(
  //                 'Followers', '${_profileData?['followers'] ?? 0}'),
  //             SizedBox(width: 32.w),
  //             _buildStatColumn(
  //                 'Following', '${_profileData?['followings'] ?? 0}'),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          CustomProfileAvatar(
            profilePicUrl: _profileData!['profilePic'],
            matchScore: _profileData!['compatibility'] ?? "0",
            avatar: _profileData!['avatar'],
            onTap: (photoUrl) {
              _showProfilePhotoDialog(photoUrl);
            },
          ),
          SizedBox(height: 16.h),
          Text(
            _profileData?['name'] ?? '',
            style: GoogleFonts.roboto(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
              fontSize: 20.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          if (_profileData?['bio'] != null && _profileData!['bio'].isNotEmpty)
            Column(
              children: [
                Text(
                  _profileData!['bio'],
                  style: GoogleFonts.roboto(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 14.sp,
                  ),
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                ),
                if (_profileData!['bio'].length > 100)
                  GestureDetector(
                    onTap: _toggleBioExpansion,
                    child: Container(
                      margin: EdgeInsets.only(top: 8.h),
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: Color(0xFF7400A5),
                        borderRadius: BorderRadius.circular(15.sp),
                        border: Border.all(
                          color: Color(0xFF7400A5),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                        child: Text(
                          isExpanded ? 'Show Less' : 'Show More',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 34.h),
                      side: BorderSide(
                        color: Color(0xFF7400A5),
                      ),
                    ),
                    onPressed: () {
                      if (_profileData?['isFollowing'] == true) {
                        _startChat(widget.userId);
                      } else {
                        Fluttertoast.showToast(
                          msg: "You need to follow this user to message them",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          backgroundColor: Colors.black87,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    },
                    child: Text(
                      'Message',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7400A5),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 34.h),
                    ),
                    onPressed: () async {
                      if (_profileData?['requestSent'] == true) return;

                      // Handle unfollow if already following
                      if (_profileData?['isFollowing'] == true) {
                        try {
                          final userProvider = Provider.of<UserProviderall>(context, listen: false);
                          final userId = userProvider.userId;
                          final token = userProvider.userToken;

                          if (userId == null || token == null) {
                            print("User credentials missing");
                            return;
                          }

                          final url = Uri.parse("${BASE_URL}api/unfollow");
                          final request = http.MultipartRequest('POST', url);

                          // Add headers
                          request.headers['userId'] = userId;
                          request.headers['token'] = token;

                          // Add form data fields
                          request.fields['otherId'] = widget.userId;

                          // Send the request
                          final response = await request.send();
                          final responseString = await http.Response.fromStream(response);

                          if (response.statusCode == 200) {
                            setState(() {
                              _profileData?['isFollowing'] = false;
                              // Optionally decrease follower count
                              if (_profileData?['followers'] != null) {
                                _profileData!['followers'] = (_profileData!['followers'] as int) - 1;
                              }
                            });
                            Fluttertoast.showToast(
                              msg: "Unfollowed successfully",
                              toastLength: Toast.LENGTH_SHORT,
                            );
                            _loadPosts(); // Reload posts since user is no longer following
                          } else {
                            print("Failed to unfollow: ${responseString.body}");
                            Fluttertoast.showToast(
                              msg: "Failed to unfollow",
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          }
                        } catch (e) {
                          print("Error unfollowing: $e");
                          Fluttertoast.showToast(
                            msg: "Error unfollowing",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        }
                        return;
                      }

                      // Handle pending request (Accept)
                      if (_profileData?['requestPending'] == true) {
                        try {
                          final response = await http.put(
                            Uri.parse("${BASE_URL}api/acceptRequest"),
                            headers: {
                              'userid': userProvider.userId ?? '',
                              'token': userProvider.userToken ?? '',
                              "Content-Type": "application/json",
                            },
                            body: jsonEncode({
                              "otherId": widget.userId,
                            }),
                          );

                          if (response.statusCode == 200) {
                            setState(() {
                              _profileData?['requestPending'] = false;
                              _profileData?['isFollowing'] = true;
                            });
                            Fluttertoast.showToast(
                              msg: "Request accepted successfully",
                              toastLength: Toast.LENGTH_SHORT,
                            );
                            _loadPosts(); // Reload posts since user is now following
                          }
                        } catch (e) {
                          print("Error accepting request: $e");
                          Fluttertoast.showToast(
                            msg: "Failed to accept request",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        }
                        return;
                      }

                      // Default case - Send friend request
                      try {
                        final response = await http.post(
                          Uri.parse("${BASE_URL}api/sendRequest"),
                          headers: {
                            'userId': userProvider.userId ?? '',
                            'token': userProvider.userToken ?? '',
                            "Content-Type": "application/json",
                          },
                          body: jsonEncode({
                            "sentTo": widget.userId,
                          }),
                        );

                        if (response.statusCode == 200) {
                          setState(() {
                            _profileData?['requestSent'] = true;
                          });
                          Fluttertoast.showToast(
                            msg: "Friend request sent",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        }
                      } catch (e) {
                        print("Error sending friend request: $e");
                        Fluttertoast.showToast(
                          msg: "Failed to send friend request",
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      }
                    },
                    child: Text(
                      _getButtonText(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn('Followers', '${_profileData?['followers'] ?? 0}'),
              SizedBox(width: 32.w),
              _buildStatColumn('Following', '${_profileData?['followings'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_profileData?['requestSent'] == true) {
      return 'Requested';
    } else if (_profileData?['requestPending'] == true) {
      return 'Accept';
    } else if (_profileData?['isFollowing'] == true) {
      return 'Unfollow';
    } else {
      return 'Add Friend';
    }
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey
                  : Colors.black,
              fontSize: 14.sp),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    // Only show posts if user is following
    if (_profileData?['public'] == 0) {
      return Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
          ),
          Center(
            child: Column(
              children: [
                Text(
                  'Private Account',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                  ),
                ),
                if (_profileData?['isFollower'] == true)
                  Text(
                    'Follow back to see their posts',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final postsWithMedia = _posts.where((post) {
      return post['data']['media'] != null && post['data']['media'].isNotEmpty;
    }).toList();
    
    // Sort posts by creation time (newest first)
    postsWithMedia.sort((a, b) {
      final aTime = a['createdAt'] ?? 0;
      final bTime = b['createdAt'] ?? 0;
      return bTime.compareTo(aTime); // Descending order (newest first)
    });

    if (postsWithMedia.isEmpty) {
      return Center(
        child: Text(
          'No Posts',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontSize: 16,
          ),
        ),
      );
    }

    // Non-scrollable grid
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 2,
      ),
      itemCount: postsWithMedia.length,
      itemBuilder: (context, index) {
        final post = postsWithMedia[index];
        final List<dynamic> mediaList = post['data']['media'];
        final String mediaUrl = mediaList.isNotEmpty ? mediaList[0]['url'] : '';

        final bool isVideo = mediaUrl.toLowerCase().endsWith('.mp4') ||
            mediaUrl.toLowerCase().endsWith('.mov') ||
            mediaUrl.toLowerCase().endsWith('.webm');

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailsScreen(feedId: post['feedId']),
              ),
            );
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
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunitiesTab(
      BuildContext context, String userId, UserProviderall userProvider) {
    return UserCommunitiesListView(
      userId: userId,
      userProvider: userProvider,
    );
  }

  List<dynamic> _getThoughtPosts() {
    return _posts.where((post) {
      final media = post['data']['media'];
      return media == null || media.isEmpty;
    }).toList();
  }

  Widget _buildThoughtsTab() {
    final thoughtPosts = _getThoughtPosts();

    if (_isLoadingPosts) {
      return Center(child: CircularProgressIndicator());
    }

    if (thoughtPosts.isEmpty) {
      return Center(
        child: Text(
          'No Quotes To Show',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      );
    }

    return ListView.builder(
      physics: NeverScrollableScrollPhysics(), // Disable scrolling
      shrinkWrap: true, // Allow list to take only needed space
      itemCount: thoughtPosts.length,
      itemBuilder: (context, index) {
        final post = thoughtPosts[index];
        final content = post['data']['content'] ?? 'No content';
        final createdAt = post['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(post['createdAt'] * 1000)
            : null;
        final formattedDate = createdAt != null
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
            : '';
        final profilePic = post['profilePic'] ?? '';
        final name = post['name'] ?? 'Unknown';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailsScreen(feedId: post['feedId']),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(profilePic),
                        radius: 20,
                      ),
                      SizedBox(width: 10),
                      Text(name,
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      Spacer(),
                      Text(formattedDate,
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(content,
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.favorite_border,
                          color: Colors.grey, size: 18.sp),
                      const SizedBox(width: 4),
                      Text(
                        post['reactionCount'].toString(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Column(
          children: [
            // App Bar
            AppBar(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${_profileData?['name']}',
                style: GoogleFonts.leagueSpartan(
                    fontSize: 24.sp, fontWeight: FontWeight.w400),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PopupMenuButton<String>(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'block') {
                        blockUser(context, widget.userId);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBarScreen()));
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'block',
                        child: Text(
                          'Block User',
                          style: GoogleFonts.poppins(color: Colors.redAccent),
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                  ),
                ),
              ],
            ),

            // Main Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    _buildHeader(),

                    // Interests Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 15.h),
                      child: interests.isEmpty
                          ? SizedBox()
                          : Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A3A),
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
                                  SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: [
                                      ...(showAllInterests
                                          ? interests
                                          : interests.take(3))
                                          .map((interest) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 8.0),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF7400A5),
                                            borderRadius:
                                                BorderRadius.circular(20),
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
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 8.0),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF7400A5),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              showAllInterests
                                                  ? 'Show Less'
                                                  : 'Show +${interests.length - 3}',
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
                    ),

                    // Tab Bar
                    TabBar(
                      indicatorColor: Color(0xFF7400A5),
                      labelStyle: GoogleFonts.poppins(
                        color: Color(0xFF7400A5),
                      ),
                      unselectedLabelColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                      unselectedLabelStyle: GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      dividerColor: Colors.transparent,
                      controller: _tabController,
                      padding: EdgeInsets.only(right: 12.0),
                      isScrollable: true,
                      tabs: [
                        Tab(text: "Posts (${postsCount})"),
                        Tab(text: "Quote (${quotesCount})"),
                        Tab(text: "Community (${communityCount})"),
                      ],
                      tabAlignment: TabAlignment.center,
                    ),

                    // Tab Content
                    [
                      _buildPostsTab(),
                      _buildThoughtsTab(),
                      _buildCommunitiesTab(
                          context, widget.userId, userProvider),
                    ][_tabController.index],

                    // Add some bottom padding
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomProfileAvatar extends StatelessWidget {
  final String? profilePicUrl;
  final String matchScore;
  final String? avatar;
  final Function(String?)? onTap;

  const CustomProfileAvatar(
      {Key? key,
      this.profilePicUrl,
      required this.matchScore,
      required this.avatar,
      this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(profilePicUrl ?? avatar);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular border with gradient
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7400A5),
                  Color(0xFF7400A5),
                ],
              ),
            ),
          ),

          // Profile Picture or Placeholder
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.grey.shade200,
                  width: 3),
              image: profilePicUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profilePicUrl!),
                      fit: BoxFit.cover,
                    )
                  : DecorationImage(
                      image: NetworkImage(avatar!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: profilePicUrl == null
                ? Image(
                    image: NetworkImage(avatar!),
                  )
                : null,
          ),

          // Match Score Indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF7400A5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${matchScore}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnailWidget({required this.videoUrl, Key? key})
      : super(key: key);

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.pause();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
