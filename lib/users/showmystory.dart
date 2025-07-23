import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/utils/storyAvatar.dart';
import 'package:story_view/story_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:photo_view/photo_view.dart';

class MyStoryViewPage extends StatefulWidget {
  final List<Story_Item> stories;
  const MyStoryViewPage({required this.stories});

  @override
  _MyStoryViewPageState createState() => _MyStoryViewPageState();
}

class _MyStoryViewPageState extends State<MyStoryViewPage>
    with SingleTickerProviderStateMixin {
  final StoryController controller = StoryController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<StoryItem> storyItems = [];
  List<Viewer> viewers = [];
  bool isLoading = true;
  bool isViewerListOpen = false;
  int currentStoryIndex = 0;
  bool _isAnimationInitialized = false;
  bool _areStoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    // Don't call _loadStories here
    _fetchStoryViewers(widget.stories[0].storyid);

    // Initialize only the animation controller here
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize the animation here, after MediaQuery is available
    if (!_isAnimationInitialized) {
      _animation = Tween<double>(
        begin: 0,
        end: MediaQuery.of(context).size.height * 0.5,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _animation.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      _isAnimationInitialized = true;
    }

    // Load stories here, after MediaQuery is available
    if (!_areStoriesLoaded) {
      _loadStories();
      _areStoriesLoaded = true;
    }
  }

  void _loadStories() {
    storyItems = widget.stories.map((story) {
      // Create a display that shows the original image without modifications
      return StoryItemExtension.customView(
        controller: controller,
        duration: const Duration(seconds: 5),
        view: Container(
          color: Colors.black,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: PhotoView(
              imageProvider: NetworkImage(story.imageUrl),
              backgroundDecoration: BoxDecoration(color: Colors.transparent),
              customSize: null,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.contained,
              initialScale: PhotoViewComputedScale.contained,
              disableGestures: true,
              heroAttributes: null,
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                ),
              ),
              errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48)),
              tightMode: true,
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<ImageInfo> _getImageInfo(String imageUrl) async {
    final Completer<ImageInfo> completer = Completer();
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        completer.complete(info);
      },
      onError: (exception, stackTrace) {
        completer.completeError(exception);
      },
    );

    final ImageProvider provider = NetworkImage(imageUrl);
    final ImageStream stream = provider.resolve(ImageConfiguration());
    stream.addListener(listener);

    return completer.future.whenComplete(() {
      stream.removeListener(listener);
    });
  }

  void _onStoryChanged(StoryItem storyItem, int index) {
    if (currentStoryIndex != index) {
      setState(() {
        currentStoryIndex = index; // Update to correct story
        isLoading = true;
        viewers = [];
      });
      _fetchStoryViewers(widget.stories[currentStoryIndex].storyid);
    }
  }

  void _toggleViewerList() {
    setState(() {
      isViewerListOpen = !isViewerListOpen;
      if (isViewerListOpen) {
        _animationController.forward();
        controller.pause();
      } else {
        _animationController.reverse();
        controller.play();
      }
    });
  }

  void _closeViewerList() {
    if (isViewerListOpen) {
      setState(() {
        isViewerListOpen = false;
        _animationController.reverse();
        controller.play();
      });
    }
  }

  Future<void> _deleteStory() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) {
      print("User credentials missing");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}api/archieve-story'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: jsonEncode({
          "storyId": widget.stories[currentStoryIndex].storyid,
        }),
      );

      if (response.statusCode == 200) {
        print('Story deleted successfully');
        // Close the story view after successful deletion
        if (mounted) Navigator.pop(context);
      } else {
        print('Failed to delete story: ${response.body}');
      }
    } catch (e) {
      print('Error deleting story: $e');
    }
  }

  Future<String?> fetchProfile(String userID) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      print('User ID or token is missing');
      return null;
    }

    final Uri url = Uri.parse('${BASE_URL}api/showProfile?other=$userID');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'userid': userid,
      'token': token,
    };

    try {
      final http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        log(responseData.toString());
        if (responseData['result'] != null &&
            responseData['result'] is List &&
            responseData['result'].isNotEmpty) {
          final userDetails = responseData['result'][0];
          return userDetails['avatar']; // Return the profile picture URL
        }
      }
    } catch (error) {
      print('An error occurred: $error');
    }
    return null;
  }

  Future<void> _fetchStoryViewers(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final token = prefs.getString('user_token') ?? '';

      if (userId.isEmpty || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-story-viewers?storyId=$storyId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final viewersList = data['viewers'];
        print('Fetched viewers for story: $storyId');

        // Create a list to hold all viewers with their profile pictures
        List<Viewer> viewersWithProfiles = [];

        if (viewersList is List) {
          // Fetch profile for each viewer
          for (var viewer in viewersList) {
            final String? profilePic = await fetchProfile(viewer['userId']);
            viewersWithProfiles.add(Viewer(
              userId: viewer['userId'],
              name: viewer['name'],
              profUrl: profilePic ?? '', // Use empty string if null
            ));
          }
        }

        if (mounted) {
          setState(() {
            viewers = viewersWithProfiles;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          viewers = [];
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProviderall>(context).profilePic;
    final userName = Provider.of<UserProviderall>(context).userName;
    if (!_isAnimationInitialized)
      return Container(); // Return empty container while initializing

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.black,
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 0),
              child: Center(
                child: StoryView(
                  storyItems: storyItems,
                  controller: controller,
                  onStoryShow: (storyItem, index) {
                    // Initially pause story to allow image loading
                    controller.pause();

                    // After a short delay, check if image is loaded and play
                    Future.delayed(Duration(milliseconds: 500), () {
                      if (mounted) controller.play();
                      _onStoryChanged(storyItem, index);
                    });
                  },
                  onComplete: () => Navigator.pop(context),
                  onVerticalSwipeComplete: (direction) {
                    if (direction == Direction.down) {
                      Navigator.pop(context);
                    }
                  },
                  progressPosition: ProgressPosition.top,
                ),
              ),
            ),
            _buildHeader(userProfile ?? '', userName ?? ''),
            _buildViewerPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userProfile, String name) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  print(widget.stories[currentStoryIndex].name);
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(userProfile),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${widget.stories[currentStoryIndex].ago}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showDeleteConfirmation(),
                child: Text(
                  "Delete Story",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Color(0xFF7400A5), width: 1.0),
          ),
          title: Column(
            children: [
              SvgPicture.asset(
                'assets/images/bondlogog.svg',
                width: 25.w,
                height: 50.h,
              ),
              SizedBox(height: 12.h),
              Text(
                'Delete Story',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this story?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 14,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirm delete
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7400A5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );

    // Only delete the story if user confirmed
    if (result == true) {
      _deleteStory();
    }
  }

  Widget _buildViewerPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: _toggleViewerList,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: _animation.value + 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildDragHandle(),
                  if (!isViewerListOpen) _buildViewerSummary(),
                  if (isViewerListOpen) _buildViewerList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildViewerSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          isLoading ? 'Loading...' : '${viewers.length} views',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildViewerList() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewers.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                            userId: viewers[index].userId,
                          )));
            },
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: viewers[index].profUrl.isNotEmpty
                    ? NetworkImage(viewers[index].profUrl)
                    : AssetImage('assets/avatar/2.png') as ImageProvider,
              ),
              title: Text(
                viewers[index].name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class Viewer {
  final String userId;
  final String name;
  final String profUrl;

  Viewer({required this.userId, required this.name, required this.profUrl});
}

extension StoryItemExtension on StoryItem {
  static StoryItem customView({
    required Widget view,
    required StoryController controller,
    Duration? duration,
  }) {
    return StoryItem(
      view,
      duration: duration ?? const Duration(seconds: 3),
      shown: false,
    );
  }
}
