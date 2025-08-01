import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:expandable_text/expandable_text.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;
  final bool isCommunity;
  int? reactionCount;
  String? userReaction;
  Map<String, dynamic>? reactionDetails;

  Post({
    required this.id,
    required this.content,
    this.media,
    required this.agoTime,
    required this.feedId,
    required this.reactions,
    required this.usrname,
    required this.commentcount,
    required this.likecount,
    required this.hasReacted,
    required this.userid,
    this.reactionType,
    this.profilepic,
    this.isCommunity = false,
    this.reactionCount,
    this.userReaction,
    this.reactionDetails,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted = reaction['hasReacted'] ?? false;
    final reactionType = reaction['reactionType'];

    Map<String, dynamic>? reactionDetails;
    if (json['data'] != null && json['data']['reactionDetails'] != null) {
      reactionDetails = json['data']['reactionDetails'];
    }

    return Post(
      id: json['_id'],
      content: json['data']['content'] ?? '',
      media: json['data']['media'] is List && json['data']['media'].isNotEmpty ? json['data']['media'] : null,
      agoTime: json['ago_time'],
      feedId: json['feedId'],
      reactions: extractReactions,
      usrname: json['name'] ?? '',
      commentcount: json['commentCount'] ?? 0,
      likecount: json['reactionCount'] ?? 0,
      hasReacted: hasReacted,
      reactionType: reactionType,
      profilepic: json['profilePic'] ?? '',
      userid: json['author'],
      isCommunity: json['isCommunity'] ?? false,
      reactionCount: reactionDetails?['total'] ?? 0,
      userReaction: reaction['reactionType'],
      reactionDetails: reactionDetails,
    );
  }

  void updateReactions(List<dynamic> newReactions) {
    reactions = newReactions;
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  final ApiService _apiService = ApiService();
  bool _isFetchingCommunityDetails = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.post.isCommunity) {
      _fetchCommunityPostDetails();
    }
  }

  Future<void> _fetchCommunityPostDetails() async {
    if (_isFetchingCommunityDetails) return;

    setState(() {
      _isFetchingCommunityDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found for fetching');
      }

      String communityId;
      String postId;
      if (widget.post.feedId.contains('/')) {
        final parts = widget.post.feedId.split('/');
        communityId = parts[0];
        postId = parts[1];
      } else {
        communityId = widget.post.feedId;
        postId = widget.post.id;
        print('Warning: Using post.id ($postId) as postId for community fetch. Verify this is correct.');
      }

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
            final fetchedPostData = data['post'];
            if (fetchedPostData['reactionDetails'] != null) {
              final newReactions = fetchedPostData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = fetchedPostData['reactionDetails']['total'] ?? 0;
            }
            if (fetchedPostData['reaction'] != null) {
              widget.post.userReaction = fetchedPostData['reaction']['reactionType'];
              widget.post.hasReacted = fetchedPostData['reaction']['hasReacted'] ?? false;
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch community post details.');
        }
      } else {
        throw Exception('Failed to fetch community post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching community post details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCommunityDetails = false;
        });
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: widget.post),
      ),
    );
  }

  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

  void _afterReactionUpdate() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  Future<void> _addReactionToCommunityPost(String postId, String reactionType) async {
    if (postId.isEmpty || reactionType.isEmpty) {
      print('Error: postId or reactionType is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User credentials not found');
      }

      String communityId;
      if (widget.post.feedId.contains('/')) {
        communityId = widget.post.feedId.split('/')[0];
      } else {
        communityId = widget.post.feedId;
      }

      setState(() {
        widget.post.hasReacted = true;
        widget.post.userReaction = reactionType;
        if (widget.post.reactionCount != null) {
          widget.post.reactionCount = (widget.post.reactionCount ?? 0) + 1;
        }
      });

      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          setState(() {
            final postData = data['post'];
            if (postData != null && postData['reactionDetails'] != null) {
              final newReactions = postData['reactionDetails']['reactions'] ?? [];
              widget.post.updateReactions(newReactions);
              widget.post.reactionCount = postData['reactionDetails']['total'] ?? 0;
            }
            if (postData['reaction'] != null) {
              widget.post.userReaction = postData['reaction']['reactionType'];
              widget.post.hasReacted = postData['reaction']['hasReacted'] ?? false;
            }
          });
          _afterReactionUpdate();
        } else {
          setState(() {
            widget.post.hasReacted = false;
            widget.post.userReaction = null;
            if (widget.post.reactionCount != null) {
              widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
            }
          });
          throw Exception(data['message'] ?? 'Failed to add reaction.');
        }
      } else {
        setState(() {
          widget.post.hasReacted = false;
          widget.post.userReaction = null;
          if (widget.post.reactionCount != null) {
            widget.post.reactionCount = (widget.post.reactionCount ?? 1) - 1;
          }
        });
        throw Exception('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding community reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  Future<void> _addReaction(String reactionType) async {
    bool isCommunityPost = widget.post.feedId.contains('/') || widget.post.isCommunity;

    if (isCommunityPost) {
      String postId;
      if (widget.post.feedId.contains('/')) {
        postId = widget.post.feedId.split('/')[1];
      } else {
        postId = widget.post.feedId;
      }
      await _addReactionToCommunityPost(postId, reactionType);
    } else {
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
            setState(() {
              if (widget.post.reactions == null) {
                widget.post.reactions = [];
              }
              widget.post.reactions.removeWhere((r) => r['userId'] == userId);
              widget.post.reactions.add({
                'userId': userId,
                'reactionType': reactionType,
              });
              widget.post.likecount = widget.post.reactions.length;
            });
            _afterReactionUpdate();
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
      }
    }
  }

  Widget _buildReactionDisplayButton() {
    if (widget.post.isCommunity) {
      return Row(
        children: [
          GestureDetector(
            key: _reactionButtonKey,
            onTap: () {
              String postId = widget.post.feedId.contains('/') ? widget.post.feedId.split('/')[1] : widget.post.feedId;
              _addReactionToCommunityPost(postId, 'like');
            },
            onLongPress: () {
              final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              showMenu(
                context: context,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                position: RelativeRect.fromLTRB(
                  position.dx - 100,
                  position.dy - 80,
                  position.dx + size.width + 100,
                  position.dy + size.height,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionOptionButton('like', '👍'),
                          _buildReactionOptionButton('love', '❤️'),
                          _buildReactionOptionButton('haha', '😄'),
                          _buildReactionOptionButton('lulu', '😂'),
                        ],
                      ),
                    ),
                  ),
                ],
                elevation: 8,
              );
            },
            child: IconButton(
              icon: _getReactionIcon(),
              onPressed: null,
            ),
          ),
          Text(
            '${widget.post.reactionCount ?? widget.post.likecount}',
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final prefs = snapshot.data!;
          final userId = prefs.getString('user_id');
          final token = prefs.getString('user_token');

          if (userId == null || token == null) {
            return SizedBox.shrink();
          }

          return ReactionButton(
            entityId: widget.post.feedId,
            entityType: "feed",
            userId: userId,
            token: token,
          );
        });
  }

  Widget _getReactionIcon() {
    if (!widget.post.hasReacted) {
      return Icon(
        Icons.thumb_up_outlined,
        color: Colors.grey,
      );
    }

    switch (widget.post.userReaction?.toLowerCase()) {
      case 'like':
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
      case 'love':
        return Icon(Icons.favorite, color: Color(0xFF7400A5));
      case 'haha':
      case 'lulu':
        return Icon(Icons.sentiment_very_satisfied, color: Color(0xFF7400A5));
      default:
        return Icon(Icons.thumb_up, color: Color(0xFF7400A5));
    }
  }

  Widget _buildReactionOptionButton(String reactionType, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        String postId;
        if (widget.post.feedId.contains('/')) {
          postId = widget.post.feedId.split('/')[1];
        } else {
          postId = widget.post.feedId;
        }
        _addReactionToCommunityPost(postId, reactionType);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = widget.post.media is List ? widget.post.media as List : [];
    final isVideoPost = mediaList.any((media) => (media['url'] ?? '').toLowerCase().endsWith('.mp4') || (media['url'] ?? '').toLowerCase().endsWith('.mov'));

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade300.withOpacity(0.8), width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              final userProvider = Provider.of<UserProviderall>(context, listen: false);
              final currentUserId = userProvider.userId;

              if (widget.post.isCommunity) {
                _navigateToCommunityProfile(widget.post.userid);
              } else {
                _navigateToUserProfile(currentUserId, widget.post.userid);
              }
            },
            leading: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                _navigateToUserProfile(currentUserId, widget.post.userid);
              },
              child: CircleAvatar(
                backgroundImage: widget.post.profilepic == null || widget.post.profilepic!.isEmpty ? const AssetImage('assets/avatar/4.png') : CachedNetworkImageProvider(widget.post.profilepic!),
                radius: 17,
              ),
            ),
            title: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProviderall>(context, listen: false);
                final currentUserId = userProvider.userId;
                if (widget.post.isCommunity) {
                  _navigateToCommunityProfile(widget.post.userid);
                } else {
                  _navigateToUserProfile(currentUserId, widget.post.userid);
                }
              },
              child: Row(
                children: [
                  Text(
                    widget.post.usrname,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.post.isCommunity)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF7400A5),
                      ),
                    ),
                ],
              ),
            ),
            trailing: ThreeDotsMenu(
              post: widget.post,
              onPostDeleted: () {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.removePost(widget.post.id);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: mediaList.length,
                          options: CarouselOptions(
                            height: isVideoPost ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                          ),
                          itemBuilder: (BuildContext context, int index, int realIndex) {
                            final media = mediaList[index];
                            final url = media['url'] ?? '';
                            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: const Center(child: CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.view_carousel,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isVideoPost
                      ? MediaKitVideoPlayer(
                          url: mediaList.first['url'],
                          shouldPlay: true,
                        )
                      : CachedNetworkImage(
                          imageUrl: mediaList.first['url'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(height: 26, width: 26, child: SvgPicture.asset('assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      _buildReactionDisplayButton(),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => showChatRoomSheet(context, widget.post), icon: const Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          widget.post.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          expandText: 'Read more',
                          collapseText: 'Show less',
                          linkColor: const Color(0xFF7400A5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityProfile(String communityId) {
    if (communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(communityId: communityId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid community ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(String? currentUserId, String postUserId) {
    if (postUserId == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: postUserId),
        ),
      );
    }
  }
}

class ThreeDotsMenu extends StatelessWidget {
  final Post post;
  final Function? onPostDeleted;

  const ThreeDotsMenu({
    Key? key,
    required this.post,
    this.onPostDeleted,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        _showToast("Post deleted successfully");
        if (onPostDeleted != null) {
          onPostDeleted!();
        }
      } else {
        _showToast("Failed to delete post");
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      _showToast("Error deleting post");
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final isAuthor = currentUserId == post.userid;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        if (isAuthor)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit Post',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF7400A5)),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF7400A5), width: 1.0),
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ancologog.svg',
                      width: 25.w,
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'Delete Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To Delete This Post?\nThis Action Cannot Be Undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePost(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'edit':
            String currentCaption = post.content;
            String imageUrl = '';
            if (post.media != null && post.media!.isNotEmpty) {
              imageUrl = post.media![0]['url'] ?? '';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostScreen(
                  postId: post.feedId,
                  currentCaption: currentCaption,
                  imageUrl: imageUrl,
                ),
              ),
            ).then((onValue) {
              if (onValue != null && onValue) {
                final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                postsProvider.fetchPosts(
                  userProvider.userId!,
                  userProvider.userToken!,
                  forceRefresh: true,
                );
              }
            });
            break;
          case 'report':
            _showToast("Report Has Been Sent To Admin");
            break;
        }
      },
    );
  }
}

class MediaKitVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final bool shouldPlay;

  const MediaKitVideoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 0.7625,
    required this.shouldPlay,
  }) : super(key: key);

  @override
  _MediaKitVideoPlayerState createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = false;

  List<StreamSubscription> _subscriptions = [];

  late final Stream<CombinedPlayerState> _combinedPlayerStateStream;
  late StreamSubscription _combinedStreamConnection;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();
    _initializeVideo();
  }

  void _setupCombinedStream() {
    final ConnectableStream<CombinedPlayerState> rawCombinedStream = Rx.combineLatest4(
      _player.stream.playing,
      _player.stream.completed,
      _player.stream.width,
      _player.stream.height,
      (bool playing, bool completed, int? width, int? height) {
        return CombinedPlayerState(
          playing: playing,
          completed: completed,
          width: width,
          height: height,
        );
      },
    ).publish();

    _combinedPlayerStateStream = rawCombinedStream;

    _combinedStreamConnection = rawCombinedStream.connect();
    _subscriptions.add(_combinedStreamConnection);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetAndInitializeVideo();
    } else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (_hasError) return;

      if (widget.shouldPlay) {
        _player.play();
      } else {
        _player.pause();
        _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _resetAndInitializeVideo() async {
    _disposePlayer();

    _player = Player();
    _videoController = VideoController(_player);

    _setupCombinedStream();

    _isLoading = true;
    _hasError = false;
    _isMuted = false;

    if (mounted) setState(() {});
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted) {
        print('MediaKit Player Error: $error');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }));

    _subscriptions.add(_player.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        _player.seek(Duration.zero);
        _player.play();
      }
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        if (widget.shouldPlay && !_player.state.playing) {
          _player.play();
        }
      }
    }));

    try {
      await _player.open(Media(widget.url), play: false);

      if (!mounted) return;

      await _player.setVolume(_isMuted ? 0.0 : 100.0);
    } catch (e) {
      print("MediaKit initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _subscriptions.forEach((sub) => sub.cancel());
    _subscriptions.clear();

    _player.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetAndInitializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (!_hasError) {
              if (_player.state.playing) {
                _player.pause();
              } else {
                _player.play();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );

                  final int? videoWidth = combinedState.width;
                  final int? videoHeight = combinedState.height;
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  final double videoAspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;

                  final double videoHeightCalc = constraints.maxWidth / videoAspectRatio;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeightCalc,
                    child: AbsorbPointer(
                      child: Video(
                        controller: _videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              StreamBuilder<CombinedPlayerState>(
                stream: _combinedPlayerStateStream,
                builder: (context, snapshot) {
                  final CombinedPlayerState combinedState = snapshot.data ??
                      CombinedPlayerState(
                        playing: _player.state.playing,
                        completed: _player.state.completed,
                        width: _player.state.width,
                        height: _player.state.height,
                      );
                  final bool isPlaying = combinedState.playing;
                  final bool isCompleted = combinedState.completed;

                  if (!isPlaying || isCompleted) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: (() {
                        final int? videoWidth = combinedState.width;
                        final int? videoHeight = combinedState.height;
                        final double aspectRatio = (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) ? videoWidth / videoHeight : widget.aspectRatio;
                        return constraints.maxWidth / aspectRatio;
                      })(),
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.replay : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CombinedPlayerState {
  final bool playing;
  final bool completed;
  final int? width;
  final int? height;

  CombinedPlayerState({
    required this.playing,
    required this.completed,
    this.width,
    this.height,
  });
}
