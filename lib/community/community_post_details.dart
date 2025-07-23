import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:html/parser.dart';
import 'package:socialmedia/community/community_reaction_button.dart';

class CommunityPostDetailsScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic> communityData;
  
  const CommunityPostDetailsScreen({
    Key? key, 
    required this.postId,
    this.initialData,
    required this.communityData,
  }) : super(key: key);

  @override
  _CommunityPostDetailsScreenState createState() => _CommunityPostDetailsScreenState();
}

class _CommunityPostDetailsScreenState extends State<CommunityPostDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? postData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      setState(() {
        postData = widget.initialData;
        isLoading = false;
      });
    } else {
      fetchPostDetails();
    }
  }

  Future<void> fetchPostDetails() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    if (userProvider.userToken == null || userProvider.userId == null) {
      setState(() {
        errorMessage = "User not authenticated";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}api/posts/${widget.postId}'),
        headers: {
          'token': userProvider.userToken!,
          'userId': userProvider.userId!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          postData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load post: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  String decodeHtml(String input) {
    return parse(input).documentElement?.text ?? input;
  }

  Future<void> toggleReaction(String postId, bool currentHasReacted) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    if (userProvider.userToken == null || userProvider.userId == null) {
      return;
    }

    try {
      // Using the exact API endpoint from your screenshot
      final response = await http.post(
        Uri.parse('${BASE_URL}api/communities/${widget.communityData['_id']}/post/like'),
        headers: {
          'token': userProvider.userToken!,
          'userId': userProvider.userId!,
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'postId': postId,
          'reactionType': currentHasReacted ? 'unlike' : 'love', // Toggle between love and unlike
        }),
      );

      if (response.statusCode == 200) {
        // Update the local state
        setState(() {
          if (postData != null) {
            postData!['hasReacted'] = !currentHasReacted;
            postData!['reactionCount'] = currentHasReacted 
                ? (postData!['reactionCount'] as int) - 1 
                : (postData!['reactionCount'] as int) + 1;
          }
        });
      } else {
        print('Failed to toggle reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling reaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add this at the beginning of the build method after null checks
    print("Received community data: ${widget.communityData}");
    
    if (isLoading) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Community Post')),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF7400A5))),
        ),
      );
    }

    if (errorMessage != null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Community Post')),
          body: Center(child: Text(errorMessage!)),
        ),
      );
    }

    if (postData == null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Community Post')),
          body: Center(child: Text('No post data found')),
        ),
      );
    }

    final userProvider = Provider.of<UserProviderall>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Safely extract post data
    final String content = postData!['data']?['content']?.toString() ?? '';
    final List<dynamic> mediaList = postData!['data']?['media'] is List 
        ? postData!['data']['media'] as List 
        : [];
    
    // Author details
    final Map<String, dynamic> author = postData!['author'] is Map 
        ? postData!['author'] as Map<String, dynamic> 
        : {};
    
    final String authorName = author['name']?.toString() ?? 'Unknown';
    final String authorId = author['_id']?.toString() ?? '';
    final String profilePic = author['profilePic']?.toString() ?? '';
    
    // Safely extract time
    String timeAgo = '';
    try {
      if (postData!['createdAt'] != null) {
        if (postData!['createdAt'] is int) {
          timeAgo = timeago.format(DateTime.fromMillisecondsSinceEpoch(postData!['createdAt'] as int));
        } else if (postData!['createdAt'] is String) {
          timeAgo = timeago.format(DateTime.parse(postData!['createdAt'] as String));
        }
      }
    } catch (e) {
      timeAgo = 'some time ago';
    }
    
    // Counts
    final int commentCount = postData!['commentCount'] is int ? postData!['commentCount'] as int : 0;
    final int reactionCount = postData!['reactionCount'] is int ? postData!['reactionCount'] as int : 0;
    final String postId = postData!['_id']?.toString() ?? '';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Community Post'),
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author info and community badge
              // ListTile(
              //   leading: CircleAvatar(
              //     radius: 20,
              //     backgroundColor: Colors.purple,
              //     backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              //     child: profilePic.isEmpty
              //         ? Text(authorName.isNotEmpty ? authorName[0] : '?',
              //             style: TextStyle(color: Colors.white))
              //         : null,
              //   ),
              //   title: Row(
              //     children: [
              //       Text(
              //         authorName,
              //         style: GoogleFonts.roboto(
              //           fontWeight: FontWeight.bold,
              //           color: isDarkMode ? Colors.white : Colors.black,
              //         ),
              //       ),
              //       SizedBox(width: 4),
              //       Icon(Icons.verified, size: 16, color: Color(0xFF7400A5)),
              //     ],
              //   ),
              //   subtitle: Text(
              //     timeAgo,
              //     style: GoogleFonts.roboto(
              //       color: isDarkMode ? Colors.white70 : Colors.black54,
              //       fontSize: 12,
              //     ),
              //   ),
              // ),
              // SizedBox(height: 12),
      
              // Community info
              // ListTile(
              //   leading: CircleAvatar(
              //     radius: 20,
              //     backgroundColor: Colors.purple,
              //     backgroundImage: widget.communityData.containsKey('profilePicture') && 
              //                     widget.communityData['profilePicture'] != null && 
              //                     widget.communityData['profilePicture'].toString().isNotEmpty
              //         ? NetworkImage(widget.communityData['profilePicture'].toString())
              //         : null,
              //     child: !widget.communityData.containsKey('profilePicture') || 
              //            widget.communityData['profilePicture'] == null || 
              //            widget.communityData['profilePicture'].toString().isEmpty
              //         ? Text(widget.communityData.containsKey('name') && 
              //               widget.communityData['name'] != null && 
              //               widget.communityData['name'].toString().isNotEmpty
              //               ? widget.communityData['name'].toString()[0]
              //               : 'C',
              //               style: TextStyle(color: Colors.white))
              //         : null,
              //   ),
              //   title: Row(
              //     children: [
              //       Text(
              //         widget.communityData.containsKey('name') && widget.communityData['name'] != null
              //             ? widget.communityData['name'].toString()
              //             : 'Community',
              //         style: GoogleFonts.roboto(
              //           fontWeight: FontWeight.bold,
              //           color: isDarkMode ? Colors.white : Colors.black,
              //         ),
              //       ),
              //       SizedBox(width: 4),
              //       Icon(Icons.group, size: 16, color: Color(0xFF7400A5)),
              //     ],
              //   ),
              //   subtitle: Text(
              //     'Community',
              //     style: GoogleFonts.roboto(
              //       color: isDarkMode ? Colors.white70 : Colors.black54,
              //       fontSize: 12,
              //     ),
              //   ),
              // ),
              // SizedBox(height: 12),
      
              // Post content
              if (content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    decodeHtml(content),
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
      
              // Media content
              if (mediaList.isNotEmpty)
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
                  child: mediaList.length > 1
                      ? CarouselSlider(
                          options: CarouselOptions(
                            height: MediaQuery.of(context).size.height * 0.4,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: false,
                          ),
                          items: mediaList.map<Widget>((item) {
                            return _buildMediaItem(item);
                          }).toList(),
                        )
                      : _buildMediaItem(mediaList[0]),
                ),
      
              // Interaction buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Comment button
                    InkWell(
                      onTap: () {
                        // Handle comment
                        try {
                          final postObj = Post(
                            id: postId,
                            content: content,
                            media: mediaList,
                            agoTime: timeAgo,
                            feedId: postId,
                            reactions: postData!['reactions'] is List ? postData!['reactions'] as List : [],
                            usrname: authorName,
                            commentcount: commentCount,
                            likecount: reactionCount,
                            hasReacted: postData!['hasReacted'] == true,
                            userid: authorId,
                            profilepic: profilePic,
                          );
      
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentScreen(post: postObj),
                            ),
                          );
                        } catch (e) {
                          print("Error opening comments: $e");
                        }
                      },
                      child: Container(
                        height: 26,
                        width: 26,
                        child: SvgPicture.asset('assets/icons/comment-dark.svg'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$commentCount',
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    
                    // Custom like button that uses the specific API endpoint
                    CommunityReactionButton(
                      postId: postId,
                      communityId: widget.communityData['_id'] ?? '',
                      userId: userProvider.userId!,
                      token: userProvider.userToken!,
                      initialReactionCount: reactionCount,
                      initialHasReacted: postData!['hasReacted'] == true,
                      onReactionChanged: (hasReacted, newCount) {
                        setState(() {
                          if (postData != null) {
                            postData!['hasReacted'] = hasReacted;
                            postData!['reactionCount'] = newCount;
                          }
                        });
                      },
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Send button
                    IconButton(
                      onPressed: () {
                        try {
                          // Create a Post object to pass to showChatRoomSheet
                          final postObj = Post(
                            id: postId,
                            content: content,
                            media: mediaList,
                            agoTime: timeAgo,
                            feedId: postId,
                            reactions: postData!['reactions'] is List ? postData!['reactions'] as List : [],
                            usrname: authorName,
                            commentcount: commentCount,
                            likecount: reactionCount,
                            hasReacted: postData!['hasReacted'] == true,
                            userid: authorId,
                            profilepic: profilePic,
                          );
                          showChatRoomSheet(context, postObj);
                        } catch (e) {
                          print("Error showing chat room sheet: $e");
                        }
                      },
                      icon: Icon(Icons.send, color: isDarkMode ? Colors.white : Colors.black),
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

  Widget _buildMediaItem(Map<String, dynamic> media) {
    final url = media['url']?.toString() ?? '';
    if (url.isEmpty) return SizedBox();
    
    final contentType = media['contentType']?.toString() ?? '';
    final isVideo = contentType == 'video' ||
        url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.webm') ||
        url.toLowerCase().endsWith('.mkv');

    if (isVideo) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        child: MediaKitVideoPlayer(url: url, shouldPlay: true),
      );
    } else {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: double.infinity,
        color: Colors.black,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Color(0xFF7400A5),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(Icons.error, size: 50, color: Colors.grey[600]),
              );
            },
          ),
        ),
      );
    }
  }
} 