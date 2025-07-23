import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';

class CommentScreen extends StatefulWidget {
  final Post post;

  const CommentScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _fetchedComments = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _fetchComments();
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      print('Current user ID: $userId'); // Debug print
      setState(() {
        _userId = userId;
      });
    } catch (e) {
      print('Error initializing user: $e');
    }
  }

  Future<void> _fetchComments() async {
    if (widget.post.feedId == null || widget.post.feedId.isEmpty) {
      print('Error: feedId is null or empty');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      if (widget.post.isCommunity) {
        // Handle community post comments
        String communityId;
        String postId;

        if (widget.post.feedId.contains('/')) {
          final parts = widget.post.feedId.split('/');
          communityId = parts[0];
          postId = parts[1];
        } else {
          communityId = widget.post.feedId;
          postId = widget.post.feedId;
        }

        print(
            'Fetching community comments for post: $postId in community: $communityId');

        final response = await http.get(
          Uri.parse('${BASE_URL_COMMUNITIES}api/posts/$postId'),
          headers: {
            'Content-Type': 'application/json',
            'token': token,
            'userId': userId,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['post'] != null) {
            setState(() {
              _fetchedComments = data['post']['comments'] ?? [];
            });
          } else {
            throw Exception(
                data['message'] ?? 'Failed to fetch community comments.');
          }
        } else {
          throw Exception(
              'Failed to fetch community comments: ${response.statusCode}');
        }
      } else {
        // Handle regular post comments
        print(
            'Fetching regular post comments for feedId: ${widget.post.feedId}');

        final response = await http.post(
          Uri.parse('${BASE_URL}api/getCommentsForPostId'),
          headers: {
            'Content-Type': 'application/json',
            'token': token,
            'userId': userId,
          },
          body: jsonEncode({
            'feedId': widget.post.feedId,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() {
              _fetchedComments = data['comments'] ?? [];
            });
          } else {
            throw Exception(data['message'] ?? 'Failed to fetch comments.');
          }
        } else {
          throw Exception('Failed to fetch comments: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching comments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCommunityComment(String commentId, String postId) async {
    if (commentId.isEmpty || postId.isEmpty) {
      print('Error: commentId or postId is empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      // Extract communityId from feedId (format: communityId/postId)
      final communityId = widget.post.feedId.split('/')[0];

      print('Deleting community comment: $commentId for post: $postId');
      print('Community ID: $communityId');

      final response = await http.delete(
        Uri.parse(
            '${BASE_URL}api/communities/$communityId/post/comment?postId=$postId&commentId=$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Comment deleted successfully')),
            );
          }
          _fetchComments(); // Refresh comments after deletion
        } else {
          throw Exception(data['message'] ?? 'Failed to delete comment.');
        }
      } else {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteComment(String commentId, String postId) async {
    if (commentId.isEmpty || postId.isEmpty) {
      print('Error: commentId or postId is empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.post.isCommunity) {
        // For community posts, use the community delete endpoint
        await _deleteCommunityComment(commentId, postId);
      } else {
        // For regular posts, use the existing delete endpoint
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token') ?? '';
        final userId = prefs.getString('user_id') ?? '';

        print('Deleting comment: $commentId for post: $postId');

        final response = await http.delete(
          Uri.parse('${BASE_URL}api/comment'),
          headers: {
            'Content-Type': 'application/json',
            'userid': userId,
            'token': token,
          },
          body: jsonEncode({
            'commentId': commentId,
            'postId': postId,
          }),
        );

        print('Delete response status: ${response.statusCode}');
        print('Delete response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Comment deleted successfully')),
              );
            }
            _fetchComments(); // Refresh comments after deletion
          } else {
            throw Exception(data['message'] ?? 'Failed to delete comment.');
          }
        } else {
          throw Exception('Failed to delete comment: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (widget.post.isCommunity) {
        // Handle community post comment
        String communityId;
        String postId;

        if (widget.post.feedId.contains('/')) {
          final parts = widget.post.feedId.split('/');
          communityId = parts[0];
          postId = parts[1];
        } else {
          communityId = widget.post.feedId;
          postId = widget.post.feedId;
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token') ?? '';
        final userId = prefs.getString('user_id') ?? '';

        final response = await http.post(
          Uri.parse(
              '${BASE_URL_COMMUNITIES}api/communities/$communityId/post/comment'),
          headers: {
            'Content-Type': 'application/json',
            'token': token,
            'userId': userId,
          },
          body: jsonEncode({
            'postId': postId,
            'content': _commentController.text,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            _fetchComments(); // Refresh comments
          } else {
            throw Exception(data['message'] ?? 'Failed to add comment.');
          }
        } else {
          throw Exception('Failed to add comment: ${response.statusCode}');
        }
      } else {
        // Handle regular post comment
        await _apiService.initialize();
        await _apiService.makeRequest(
          path: 'api/comment',
          method: 'POST',
          body: {
            'comment': _commentController.text,
            'postId': widget.post.feedId,
          },
        );
        _fetchComments(); // Refresh comments
      }
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    } finally {
      _commentController.clear();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addReactionToCommunityPost(
      String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      // Extract communityId from feedId
      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      print(
          'Adding reaction to community post: $postId in community: $communityId');
      print('Reaction type: $reactionType');

      final response = await http.post(
        Uri.parse(
            '${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'userId': userId,
        },
        body: jsonEncode({
          'postId': postId,
          'reactionType': reactionType,
        }),
      );

      print('Reaction response status: ${response.statusCode}');
      print('Reaction response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          // Update the post's reactions in the UI
          setState(() {
            final postData = data['post']['data'];
            if (postData != null) {
              // Update reactions
              widget.post.reactions =
                  postData['reactionDetails']['reactions'] ?? [];

              // Update reaction counts
              widget.post.reactionCount =
                  postData['reactionDetails']['total'] ?? 0;

              // Update user's reaction
              widget.post.userReaction = postData['reaction']?['reactionType'];
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    if (widget.post.isCommunity) {
      // For community posts
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
      // For regular posts
      setState(() => _isLoading = true);

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token') ?? '';
        final userId = prefs.getString('user_id') ?? '';

        final response = await http.post(
          Uri.parse('${BASE_URL}api/reaction'),
          headers: {
            'Content-Type': 'application/json',
            'token': token,
            'userId': userId,
          },
          body: jsonEncode({
            'postId': widget.post.feedId,
            'reactionType': reactionType,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            // Update the post's reactions in the UI
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              // Remove any existing reaction from this user
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              // Add the new reaction
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              // Update reaction count
              widget.post.likecount = widget.post.reactions.length;
            });
          } else {
            throw Exception(data['message'] ?? 'Failed to add reaction.');
          }
        } else {
          throw Exception('Failed to add reaction: ${response.statusCode}');
        }
      } catch (e) {
        print('Error adding reaction: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add reaction: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildCommentItem(dynamic comment) {
    if (comment == null) {
      return SizedBox.shrink();
    }

    // Debug prints to check the values
    print('Building comment item: $comment');
    print('Current user ID: $_userId');

    // Determine if this is a community comment or regular post comment
    bool isCommunityComment = widget.post.isCommunity;
    bool isOwnComment;
    String authorName;
    String authorProfilePic;
    String content;
    String timestamp;

    if (isCommunityComment) {
      isOwnComment = _userId == comment['author'];
      authorName = comment['userDetails']?['name'] ?? 'Anonymous';
      authorProfilePic = comment['userDetails']?['profilePic'];
      content = comment['content'] ?? '';
      timestamp = _formatTimeAgo(comment['createdAt']);
    } else {
      isOwnComment = _userId == comment['user']?['userId'];
      authorName = comment['user']?['name'] ?? 'Anonymous';
      authorProfilePic = comment['user']?['profilePic'];
      content = comment['comment'] ?? '';
      timestamp = comment['agoTime'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: authorProfilePic == null
                ? AssetImage('assets/avatar/4.png') as ImageProvider
                : NetworkImage(authorProfilePic),
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      authorName,
                      style: GoogleFonts.roboto(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timestamp,
                      style: GoogleFonts.roboto(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.roboto(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isCommunityComment && isOwnComment)
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: Colors.blue,
                size: 24,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Comment'),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteCommunityComment(
                              comment['_id'] ?? '',
                              widget.post.feedId.split('/')[1],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildParentPost() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]!
                : Colors.grey[400]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.post.profilepic == null
                    ? AssetImage('assets/avatar/4.png') as ImageProvider
                    : NetworkImage(widget.post.profilepic!),
                radius: 16,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.usrname ?? 'Anonymous',
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.post.agoTime ?? '',
                    style: GoogleFonts.roboto(
                        color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.post.content?.isNotEmpty ?? false)
            Text(
              widget.post.content!,
              style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 15),
            ),
          if (widget.post.media != null && widget.post.media!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.post.media![0]['url'],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.error, color: Colors.grey[600]),
                  );
                },
              ),
            )
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_fetchedComments.length} replies',
                style:
                    GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                '${widget.post.reactionCount ?? widget.post.likecount} likes',
                style:
                    GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          appBar: AppBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            title: Text(
              'Comments',
              style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildParentPost(),
                    ),
                    if (_isLoading)
                      SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_fetchedComments.isEmpty)
                      SliverFillRemaining(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No comments yet.',
                            style: GoogleFonts.roboto(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildCommentItem(_fetchedComments[index]),
                          childCount: _fetchedComments.length,
                        ),
                      ),
                  ],
                ),
              ),
              // Comment input field at bottom
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[200],
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: GoogleFonts.roboto(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                          decoration: InputDecoration(
                            hintText:
                                'Reply to ${widget.post.usrname ?? "Anonymous"}',
                            hintStyle: GoogleFonts.roboto(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isLoading
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.send, color: Color(0xFF7400A5)),
                        onPressed: _isLoading ? null : _addComment,
                      ),
                    ],
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
