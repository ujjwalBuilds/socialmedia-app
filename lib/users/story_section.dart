import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/services/agora_live_Service.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/user_apis/seeorpostmystory.dart';
import 'package:socialmedia/user_apis/uploadstory.dart';
import 'package:socialmedia/users/showmystory.dart';
import 'package:socialmedia/users/story_preview_screen.dart';
import 'package:socialmedia/users/storyviewofmyusers.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/utils/storyAvatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorySection extends StatefulWidget {
  final String userId;
  final String token;
  StorySection({Key? key, required this.token, required this.userId})
      : super(key: key);

  @override
  State<StorySection> createState() => StorySectionState();
}

class StorySectionState extends State<StorySection> {
  List<Map<String, List<Story_Item>>> stories = [];
  bool isLoading = true;
  File? _selectedImage;
  bool? islive;
  RtcEngine? _engine;
  bool _hasStories = false;
  String? profilePic;
  String? avatar;
  bool privacychecker = false;
  String? _storyAvatarUrl;
  final _storyAvatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchStories();
    checkForStories();
    _loadUserProfile();
  }

  Future<void> checkForStories() async {
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-self-stories'),
        headers: {
          'userId': widget.userId,
          'token': widget.token,
        },
      );

      print('API Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hasStories =
            (data['stories'] as List).isNotEmpty; // Explicit cast

        print('Calculated hasStories: $hasStories'); // Debug log

        if (mounted) {
          setState(() {
            _hasStories = hasStories;

            print('State updated to: $_hasStories'); // Debug log
          });
        }
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking stories: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
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

      final http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['result'] != null &&
            responseData['result'] is List &&
            responseData['result'].isNotEmpty) {
          final userDetails = responseData['result'][0];
          print('=== Profile Data Loaded ===');
          print('Raw Privacy Level: ${userDetails['privacyLevel']}');
          print('Privacy Level Type: ${userDetails['privacyLevel'].runtimeType}');
          print('Profile Pic: ${userDetails['profilePic']}');
          print('Avatar: ${userDetails['avatar']}');
          print('========================');

          if (mounted) {
            setState(() {
              profilePic = userDetails['profilePic'];
              avatar = userDetails['avatar'];
              // Convert privacy level to boolean explicitly
              final privacyLevel = userDetails['privacyLevel'];
              privacychecker = privacyLevel == 1 || privacyLevel == '1';
              print('=== Privacy Check ===');
              print('Original Privacy Level: $privacyLevel');
              print('Converted Privacy Checker: $privacychecker');
              print('====================');

              // Set story avatar URL with explicit conditions
              if (privacychecker) {
                _storyAvatarUrl = profilePic;
                print('Privacy ON - Using Profile Pic: $_storyAvatarUrl');
              } else {
                _storyAvatarUrl = avatar?.isNotEmpty == true ? avatar : profilePic;
                print('Privacy OFF - Using Avatar: $_storyAvatarUrl');
              }

              print('=== State Updated ===');
              print('Privacy Checker: $privacychecker');
              print('Profile Pic: $profilePic');
              print('Avatar: $avatar');
              print('Story Avatar URL: $_storyAvatarUrl');
              print('=====================');
            });
          }
        }
      }
    } catch (error) {
      print('An error occurred while fetching profile: $error');
    }
  }

  String getCurrentProfilePicture() {
    if (privacychecker) {
      // In anonymous mode, show avatar if available, otherwise use a fallback
      return avatar ?? ''; // Return empty string instead of null
    } else {
      // In non-anonymous mode, show profilePic if available, otherwise fallback to avatar
      return (profilePic?.isNotEmpty == true) ? profilePic! : (avatar ?? '');
    }
  }

  Future<Map<String, String>?> joinLiveStream(
    String toid,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userId == null || token == null) {
      print("User ID or Token not found in SharedPreferences");
      return null;
    }

    final Uri url = Uri.parse('${BASE_URL}api/join-live-stream');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'userid': userId
        },
        body: json.encode({
          'userId': toid,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // await SocketService().connect();
        // SocketService().joinStream(data['channelName']);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LiveAyush(
                    token: data['token'],
                    channel: data['channelName'],
                    isboradcaster: false)));
        return {
          'channelName': data['channelName'],
          'token': data['token'],
        };
      } else {
        print("Failed to join live stream: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<void> fetchStories() async {
    try {
      print('guhudaaaa');
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-stories'),
        headers: {
          'userId': widget.userId,
          'token': widget.token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        print(data);

        setState(() {
          stories = _parseStories(data['stories'])
              as List<Map<String, List<Story_Item>>>;
          print('xxxxxxx');
          //print(data['stories'][0]['isLive']);

          isLoading = false;
        });
        print('$stories');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching stories: $e');
    }
  }

  Object _parseStories(List<dynamic> storiesData) {
    List<Map<String, List<Story_Item>>> parsed = [];

    for (var userStory in storiesData) {
      final userId = userStory['userId'];
      final isLive = userStory['isLive'] ?? false;
      final hasStory = userStory['hasStory'] ?? false;
      final channelName = userStory['channelName'] ?? '';
      final name = userStory['name'] ?? ''; // Add name from API if available
      final profilepic = userStory['profilePic'] ?? '';

      // Handle case where user is live but has no stories
      if (isLive && (userStory['stories'] as List).isEmpty) {
        parsed.add({
          userId: [
            Story_Item(
                imageUrl: '', // Empty for live users without stories
                name: name,
                authorId: userId,
                createdAt: DateTime.now()
                    .millisecondsSinceEpoch, // Current time for live users
                ago: 'Live now',
                storyid: '', // Empty for live users without stories
                isLive: true,
                channelName: channelName,
                seen: 0,
                profilepic: profilepic)
          ]
        });
        continue; // Skip to next user
      }

      // Handle regular stories
      final userStories = userStory['stories'] as List<dynamic>;
      if (userStories.isNotEmpty) {
        List<Story_Item> userStoryItems = userStories.map((story) {
          return Story_Item(
              imageUrl: story['url'],
              name: name,
              authorId: story['author'],
              createdAt: story['createdAt'],
              ago: story['ago_time'],
              storyid: story['_id'],
              isLive: isLive,
              channelName: channelName,
              seen: story['seen'],
              profilepic: profilepic);
        }).toList();

        parsed.add({userId: userStoryItems});
      }
    }

    return parsed;
  }

  Future<void> _pickImage([ImageSource source = ImageSource.camera]) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final selectedImage = File(pickedFile.path);

      // Navigate to StoryPreviewScreen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryEditor(selectedImage: selectedImage),
        ),
      );

      // if (result != null && result is Map<String, dynamic>) {
      //   final image = result['image'] as File;
      //   final overlayText = result['overlayText'] as String;
      //   final textPosition = result['textPosition'] as Offset;

      //   // Upload the story with overlaid text
      //   StoryService storyService = StoryService();
      //   await storyService.uploadStory(imageBytes)
      // }
    }
  }

  void _showStory(BuildContext context, String authorId,
      List<Story_Item> stories, bool isLIVE) {
    // Find the user's story data from the stories list

    // Find if the user has a live story from the original stories data

    // Check if user has live story

    if (isLIVE) {
      // Show bottom modal sheet for live story
      showModalBottomSheet(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        context: context,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.25,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ListTile(
                    leading: Icon(Icons.wifi, color: Colors.greenAccent),
                    title: Text(
                      "Watch Live",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkText
                            : AppColors.darkText,
                      ),
                    ),
                    onTap: () async {
                      print(authorId);
                      Navigator.pop(context);

                      final result = await joinLiveStream(
                        authorId,
                      );

                      if (result == null) {
                        print(
                            "Error: Failed to retrieve channel name and token.");
                        return;
                      }

                      String channelName = result['channelName']!;
                      String streamToken = result['token']!;

                      print("Channel Name: $channelName");
                      print("Stream Token: $streamToken");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveAyush(
                            token: streamToken,
                            channel: channelName,
                            isboradcaster: false,
                          ),
                        ),
                      );
                    }),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text(
                    "View Story",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.darkText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryViewPage(stories: stories),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Directly show the story if there's no live story
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewPage(stories: stories),
        ),
      );
    }
  }

  void _showMYStory(
      BuildContext context, String authorId, List<Story_Item> stories) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyStoryViewPage(stories: stories),
      ),
    );
  }

  void _selectImageSource() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.40,
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    )),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStoryOptions() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.40,
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    )),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    if (isLoading) {
      return Container(
        height: 120.h,
        child: _buildShimmerLoading(),
      );
    }

    print('Current _hasStories in build: $_hasStories');
    print('Stories length: ${stories.length}');

    return Container(
      height: 110.h,
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.isEmpty ? 1 : stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  StoryUtils.checkAndShowStoryOptions(
                    context,
                    widget.userId,
                    widget.token,
                    _pickImage,
                    _showMYStory,
                  );
                },
                child: FittedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: _hasStories
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFF7400A5),
                                      width: 2.5,
                                    ),
                                  )
                                : null,
                            child: CircleAvatar(
                              radius: 30,
                              // Use fallback if image is null
                              backgroundImage: NetworkImage(getCurrentProfilePicture()),
                              // Add error handler in case image loading fails
                              onBackgroundImageError: (exception, stackTrace) {
                                print('Error loading profile image: $exception');
                              },
                              backgroundColor: Colors.grey[300], // Fallback background
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF7400A5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Story',
                        style: GoogleFonts.roboto(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final userStories = stories.isNotEmpty ? stories[index - 1] : {};
          final authorId = userStories.isNotEmpty ? userStories.keys.first : "";
          final storyItems =
              userStories.isNotEmpty ? userStories.values.first : [];
          final livehai =
              userStories.isNotEmpty ? storyItems.first.isLive : false;

          return Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showStory(context, authorId, storyItems, livehai!),
              child: StoryAvatar(
                story: storyItems.first,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      children: [
        // Story circles shimmer
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]!
                : Colors.grey[200]!,
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
            child: Container(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: 50,
                          height: 10,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Post shimmer items
        // ...List.generate(3, (index) => _buildShimmerPostItem()),
        // ...List.generate(3, (index) => _buildShimmerPostItem()),
      ],
    );
  }

  Widget _buildMyStoryAvatar() {
    print('=== Building MyStoryAvatar ===');
    print('Current Privacy Level: $privacychecker');
    print('Story Avatar URL: $_storyAvatarUrl');
    print('Profile Pic Available: ${profilePic != null}');
    print('Avatar Available: ${avatar != null}');

    // Verify the current state
    if (privacychecker) {
      print('Privacy is ON - Should show Profile Pic');
    } else {
      print('Privacy is OFF - Should show Avatar');
    }

    return GestureDetector(
      onTap: () => _showStoryOptions(),
      child: Container(
        width: 60.sp,
        height: 60.sp,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: _hasStories
              ? Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF7400A5)
                      : Colors.deepPurpleAccent,
                  width: 2)
              : null,
        ),
        child: Stack(
          children: [
            CircleAvatar(
              key: _storyAvatarKey,
              radius: 30.sp,
              backgroundColor: Colors.grey[300],
              backgroundImage: _storyAvatarUrl != null && _storyAvatarUrl!.isNotEmpty
                  ? NetworkImage(_storyAvatarUrl!)
                  : null,
              child: (_storyAvatarUrl == null || _storyAvatarUrl!.isEmpty)
                  ? Icon(
                      Icons.person,
                      size: 30.sp,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4.sp),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF7400A5)
                      : Colors.deepPurpleAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
