import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/constants.dart';

class PostDetailsScreen extends StatefulWidget {
  final String feedId;
  final Map<String, dynamic>? initialPostData;

  const PostDetailsScreen({
    Key? key,
    required this.feedId,
    this.initialPostData,
  }) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? postData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialPostData != null) {
      setState(() {
        postData = widget.initialPostData;
        isLoading = false;
      });
    } else {
      fetchPostDetails();
    }
  }

  void navigateToCommentScreen(BuildContext context) {
    log(widget.feedId);
    if (postData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post data not available')),
      );
      return;
    }
    log("Post Data: $postData");
    try {
      // Create a safe copy of the post data with proper null checks
      final Map<String, dynamic> safePostData =
          Map<String, dynamic>.from(postData!);

      // Safely extract media list with explicit empty list fallback
      List<dynamic> mediaList = [];
      if (safePostData['data'] != null &&
          safePostData['data'] is Map<String, dynamic> &&
          safePostData['data']['media'] != null &&
          safePostData['data']['media'] is List) {
        mediaList = List<dynamic>.from(safePostData['data']['media']);
      }

      // Safely extract reactions with explicit empty list fallback
      List<dynamic> reactionsList = [];
      if (safePostData['reactions'] != null &&
          safePostData['reactions'] is List) {
        reactionsList = List<dynamic>.from(safePostData['reactions']);
      }

      // Safely extract author details with explicit empty map fallback
      final authorDetails = (safePostData['authorDetails'] != null &&
              safePostData['authorDetails'] is Map)
          ? safePostData['authorDetails']
          : {};

      final post = Post(
        id: safePostData['_id']?.toString() ?? '',
        content: (safePostData['data'] != null &&
                safePostData['data']['content'] != null)
            ? safePostData['data']['content'].toString()
            : '',
        media: mediaList,
        agoTime: safePostData['agoTime']?.toString() ?? '',
        feedId: safePostData['feedId']?.toString() ?? '',
        reactions: reactionsList,
        commentcount: (safePostData['commentCount'] is num)
            ? (safePostData['commentCount'] as num).toInt()
            : 0,
        likecount: (safePostData['reactionCount'] is num)
            ? (safePostData['reactionCount'] as num).toInt()
            : 0,
        usrname: (authorDetails != null && authorDetails['name'] != null)
            ? authorDetails['name'].toString()
            : 'Anonymous',
        userid: (authorDetails != null && authorDetails['userId'] != null)
            ? authorDetails['userId'].toString()
            : '',
        hasReacted: safePostData['hasReacted'] == true,
        reactionType: safePostData['reactionType']?.toString() ?? '',
        profilepic:
            (authorDetails != null && authorDetails['profilePic'] != null)
                ? authorDetails['profilePic'].toString()
                : '',
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CommentScreen(post: post)),
      ).then((_) {
        // Refresh post data when returning from comments
        fetchPostDetails();
      });
    } catch (e, stackTrace) {
      print("Error creating Post object: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening comments: $e")),
      );
    }
  }

  void _showPostOptions() async {
    if (postData == null) return;
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final authorId = postData!['authorDetails']['userId'];
    final isAuthor = currentUserId == authorId;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(isAuthor ? Icons.delete : Icons.report,
                    color: isAuthor ? Colors.red : Colors.orange),
                title: Text(
                  isAuthor ? 'Delete Post' : 'Report',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the modal
                  if (isAuthor) {
                    await _deletePost();
                  } else {
                    Fluttertoast.showToast(
                      msg: "Report Has Been Sent To Admin",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                },
              ),
              if (isAuthor)
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text(
                    'Edit Post',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the modal

                    // Extract current caption from postData
                    String currentCaption = postData!['data']['content'] ?? '';

                    // Extract image URL from the first media item (if exists)
                    String imageUrl = '';
                    if (postData!['data']['media'] != null &&
                        postData!['data']['media'] is List &&
                        postData!['data']['media'].isNotEmpty) {
                      imageUrl = postData!['data']['media'][0]['url'] ?? '';
                    }

                    // Navigate to edit post screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditPostScreen(
                                  postId: widget.feedId,
                                  currentCaption: currentCaption,
                                  imageUrl: imageUrl,
                                )));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePost() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;
    if (userId == null || token == null || postData == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": postData!['feedId'],
        }),
      );

      if (response.statusCode == 200) {
        print('Post deleted successfully');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => user_profile()));

        // Go back after deletion
      } else {
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  Future<void> fetchPostDetails() async {
    if (widget.initialPostData != null) {
      setState(() {
        postData = widget.initialPostData;
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-post-details?feedId=${widget.feedId}'),
        headers: {
          'userId': userProvider.userId!,
          'token': userProvider.userToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            postData = data['post'];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Failed to load post. Status code: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error fetching post details: $e';
          isLoading = false;
        });
      }
      print(errorMessage);
    }
  }

  // Add this method to safely extract content and media
  Map<String, dynamic> _getPostContent() {
    if (postData == null) return {};

    // For community posts, content and media might be directly in the post
    if (postData!['content'] != null) {
      return {
        'content': postData!['content']?.toString() ?? '',
        'media': postData!['media'] is List ? postData!['media'] : [],
      };
    }

    // For regular posts, content and media are in the 'data' field
    if (postData!['data'] != null && postData!['data'] is Map) {
      return {
        'content': postData!['data']['content']?.toString() ?? '',
        'media': postData!['data']['media'] is List
            ? postData!['data']['media']
            : [],
      };
    }

    return {'content': '', 'media': []};
  }

  Map<String, dynamic> _getAuthorDetails() {
    if (postData == null) return {};

    // Check if this is a community post
    if (postData!['author'] != null && postData!['author'] is Map) {
      final author = postData!['author'] as Map<String, dynamic>;
      return {
        'userId': author['_id']?.toString() ?? '',
        'name': author['name']?.toString() ?? 'Unknown',
        'profilePic': author['profilePic']?.toString() ?? '',
      };
    }

    // Regular post with authorDetails
    if (postData!['authorDetails'] != null &&
        postData!['authorDetails'] is Map) {
      return postData!['authorDetails'];
    }

    return {'userId': '', 'name': 'Unknown', 'profilePic': ''};
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Post')),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (errorMessage != null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Post')),
          body: Center(child: Text(errorMessage!)),
        ),
      );
    }

    if (postData == null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Post')),
          body: Center(child: Text('No post data found')),
        ),
      );
    }

    final userProvider = Provider.of<UserProviderall>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use the helper methods to get post data safely
    final authorDetails = _getAuthorDetails();
    final postContent = _getPostContent();
    final content = postContent['content'] as String;
    final mediaList = postContent['media'] as List;
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Post'),
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author info row
              ListTile(
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: authorDetails['userId'] ?? '',
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: authorDetails['profilePic'] != null && 
                                    authorDetails['profilePic'].toString().isNotEmpty
                        ? NetworkImage(authorDetails['profilePic'].toString())
                        : null,
                    child: authorDetails['profilePic'] == null || 
                           authorDetails['profilePic'].toString().isEmpty
                        ? Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
                title: Text(
                  authorDetails['name']?.toString() ?? 'Unknown',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  postData!['agoTime']?.toString() ?? '',
                  style: GoogleFonts.roboto(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    _showPostOptions();
                  },
                ),
              ),
              SizedBox(height: 12),
      
              // Post content
              if (content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    content,
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
      
              // Reaction and comment section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Reaction button
                    SizedBox(
                      width: 15,
                    ),
                    InkWell(
                      onTap: () {
                        navigateToCommentScreen(context);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 30,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                          SizedBox(width: 6),
                          Text(
                            postData!['commentCount']?.toString() ?? '0',
                            style: GoogleFonts.roboto(
                              color: isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
      
                    SizedBox(
                      width: 25,
                    ),
                    ReactionButton(
                      entityId: postData!['feedId'],
                      entityType: "feed",
                      userId: userProvider.userId!,
                      token: userProvider.userToken!,
                    ),
      
                    // Comment button
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        color: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600]),
      );
    }

    return Image.network(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 40,
          height: 40,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 40,
          height: 40,
          color: Colors.grey[300],
          child: Icon(Icons.person, color: Colors.grey[600]),
        );
      },
    );
  }

  Widget _buildMediaItem(Map<String, dynamic> media) {
    final url = media['url'] ?? '';
    final contentType = media['contentType'] as String?;
    final isVideo = contentType == 'video' ||
        url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.webm') ||
        url.toLowerCase().endsWith('.mkv');

    if (isVideo) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: MediaKitVideoPlayer(url: url, shouldPlay: true),
      );
    } else {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
