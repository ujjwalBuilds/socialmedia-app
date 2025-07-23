import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/community/community_post_details.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/community/communityApiService.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;

  const CommunityDetailScreen({Key? key, required this.communityId})
      : super(key: key);

  @override
  _CommunityDetailScreenState createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic> communityData = {};
  List<dynamic> communityPosts = [];
  bool isJoined = false;

  @override
  void initState() {
    super.initState();
    fetchCommunityDetails();
  }

  Future<void> fetchCommunityDetails() async {
    try {
      // Get token and userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      // Set headers with authorization token
      final headers = {
        'token': token,
        'userId': userId,
        'Content-Type': 'application/json',
      };

      // Fetch community details
      final Uri communityUrl = Uri.parse(
          '${BASE_URL_COMMUNITIES}api/communities/${widget.communityId}');
      final communityResponse = await http.get(communityUrl, headers: headers);

      if (communityResponse.statusCode == 200) {
        final data = json.decode(communityResponse.body);

        // Check if user is a member of this community
        if (data['members'] != null && data['members'] is List) {
          setState(() {
            isJoined = (data['members'] as List).contains(userId);
          });
        }

        // Fetch community posts
        final Uri postsUrl = Uri.parse(
            '${BASE_URL_COMMUNITIES}api/communities/${widget.communityId}/post');
        final postsResponse = await http.get(postsUrl, headers: headers);

        if (postsResponse.statusCode == 200) {
          final postsData = json.decode(postsResponse.body);
          List<dynamic> posts = postsData['posts'] ?? [];

          setState(() {
            communityData = data;
            communityPosts = posts;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load community posts');
        }
      } else {
        throw Exception('Failed to load community details');
      }
    } catch (e) {
      print('Error fetching community details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _joinOrLeaveCommunity() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null) {
      final action = isJoined ? 'remove' : 'join';
      final success = await CommunityService().joinOrLeaveCommunity(
        userId,
        widget.communityId,
        action,
      );

      if (success) {
        // Update local state
        setState(() {
          isJoined = !isJoined;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isJoined
                  ? 'Successfully joined the community!'
                  : 'Successfully left the community!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white , fontWeight: FontWeight.bold),
            ),
            backgroundColor: isJoined ? Colors.green : Colors.red,
          ),
        );

        // Refresh community data
        fetchCommunityDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${isJoined ? 'leave' : 'join'} the community.',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to join or leave communities.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: isLoading
              ? Text('Community',
                  style: GoogleFonts.roboto(color: Colors.white))
              : InkWell(
                  onTap: () {
                    print('Tapped on community name: ${widget.communityId}');
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityScreen(
                            communityId: widget.communityId,
                          ),
                        ),
                      );
                    } catch (e) {
                      print('Error navigating to community screen: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error opening community: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        backgroundImage: communityData['profilePicture'] != null
                            ? NetworkImage(communityData['profilePicture'])
                            : null,
                        radius: 16,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          communityData['name'] ?? 'Community',
                          style: GoogleFonts.roboto(
                            color: Color(0xFF7400A5),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Color(0xFF333333),
                  builder: (context) => _buildOptionsSheet(),
                );
              },
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7400A5)))
            : Column(
                children: [
                  Divider(color: Colors.grey.shade800, height: 1),

                  // Community posts directly without the About section
                  Expanded(
                    child: communityPosts.isEmpty
                        ? Center(
                            child: Text(
                              'No posts in this community',
                              style: GoogleFonts.roboto(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            itemCount: communityPosts.length,
                            itemBuilder: (context, index) {
                              final post = communityPosts[index];
                              return CommunityPostWidget(post: post);
                            },
                          ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Container(
            color: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 22.h),
            child: Text(
              'Only Community Admins Can Message',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSheet() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.white),
            title: Text(
              isJoined ? 'Leave Community' : 'Join Community',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _joinOrLeaveCommunity();
            },
          ),
          ListTile(
            leading: Icon(Icons.report, color: Colors.white),
            title: Text('Report Community',
                style: GoogleFonts.roboto(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report functionality coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CommunityPostWidget extends StatelessWidget {
  final Map<String, dynamic> post;

  const CommunityPostWidget({
    Key? key,
    required this.post,
  }) : super(key: key);

  String _getTimeAgo() {
    try {
      // Handle both string and timestamp formats
      final DateTime createdAt = post['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(post['createdAt'])
          : DateTime.parse(post['createdAt'].toString());
      return timeago.format(createdAt);
    } catch (e) {
      print('Error parsing date: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get post content with proper handling for different data structures
    final String content = post['data'] is Map
        ? post['data']['content'] ?? 'No content'
        : post['content'] ?? 'No content';

    final data =
        post['data'] is Map ? post['data'] as Map<String, dynamic> : {};
    final mediaList = data['media'];
    final bool hasMedia =
        mediaList != null && mediaList is List && mediaList.isNotEmpty;
    String? mediaUrl;
    if (hasMedia) {
      mediaUrl = mediaList[0]['url'];
    }

    return GestureDetector(
      onTap: () {
        // Extract community data for navigation
        final String postId = post['_id']?.toString() ?? '';
        final Map<String, dynamic> communityData = {
          'name': post['community']?['name'] ?? 'Community',
          'profilePicture': post['community']?['profilePicture'] ?? '',
          '_id': post['community']?['_id'] ?? '',
        };

        // Navigate to post details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostDetailsScreen(
              postId: postId,
              initialData: post,
              communityData: communityData,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.teal.withOpacity(0.3), width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Container(
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Colors.teal.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text content
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 4.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReadMoreText(
                            content,
                            trimLines:
                                2, // Number of lines before "Read More" appears
                            textAlign:
                                TextAlign.justify, // Justify text alignment
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                            colorClickableText: const Color(
                                0xFF7400A5), // Color for clickable text
                            trimMode: TrimMode.Line, // Trim based on lines
                            trimCollapsedText:
                                ' Read More', // Text when collapsed
                            trimExpandedText: ' Show Less', // Text when expanded
                          ),
                        ],
                      ),
                    ),

                    // Media content (if available)
                    if (hasMedia && mediaUrl != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                        child: Container(
                          width: double.infinity,
                          height: 200.h,
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.sp))),
                          // Use ClipRRect to force the image to respect the rounded corners
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.sp)),
                            child: CachedNetworkImage(
                              imageUrl: mediaUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF7400A5)),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Post timestamp
                    Padding(
                      padding: EdgeInsets.all(8.r),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getTimeAgo(),
                            style: GoogleFonts.roboto(
                              color: Colors.grey,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
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
