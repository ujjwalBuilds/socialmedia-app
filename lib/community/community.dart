import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/bottom_nav_bar/post_Screen.dart';
import 'package:socialmedia/community/communityApiService.dart';
import 'package:socialmedia/user_apis/post_api.dart';
import 'package:socialmedia/users/editPost.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:html/parser.dart' show parse;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/community/community_post_details.dart';
import 'package:socialmedia/community/members_screen.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'dart:async';
import 'package:rxdart/rxdart.dart';

class CommunityScreen extends StatefulWidget {
  final String communityId;

  const CommunityScreen({
    Key? key,
    required this.communityId,
  }) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<Map<String, dynamic>> futureCommunity;
  bool isJoined = false;

  final List<Map<String, dynamic>> _posts = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    futureCommunity = fetchCommunity(widget.communityId);
    _fetchInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasNextPage && !_isLoadingMore) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchInitialPosts() async {
    setState(() {
      futureCommunity = fetchCommunity(widget.communityId);
      _isFirstLoad = true;
      _posts.clear();
      _currentPage = 1;
      _hasNextPage = true;
    });
    await fetchCommunityPosts(widget.communityId, page: 1);
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() {
      _isLoadingMore = true;
    });
    await fetchCommunityPosts(widget.communityId, page: _currentPage + 1);
  }

  Future<Map<String, dynamic>> fetchCommunity(String communityId) async {
    print("%%%%%%%%%% fetchCommunity called with communityId: $communityId");
    final prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');
    print("SharedPreferences loaded: userid=$userid, token=$token");
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'userid': userid ?? '',
      'token': token ?? '',
    };
    print("@@@@@@@@@@ Headers for request: $headers");
    final url = '${BASE_URL_COMMUNITIES}api/communities/$communityId/communityDetailsWithoutPostAndMembersData';
    print("########## Fetching community details from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    print("********** HTTP response status: ${response.statusCode}");
    print("^^^^^^^^^^ HTTP response body: ${response.body}");

    if (response.statusCode == 200) {
      print("This is the API causing error######################");
      final data = json.decode(response.body);
      print("&&&&&&&&&& Decoded data: $data");
      if (mounted) {
        setState(() {
          isJoined = data['isJoined'] ?? false;
          print("(((((((((()))))))))) isJoined set to: $isJoined");
        });
      } else {
        print("!!!!!!!!!! Widget not mounted, skipping setState");
      }
      return data;
    } else {
      print("!!!!!!!!!! Failed to load community, status: ${response.statusCode}");
      throw Exception('Failed to load community');
    }
  }

  Future<void> fetchCommunityPosts(String communityId, {required int page}) async {
    print("%%%%%%%%%% fetchCommunityPosts called with communityId: $communityId, page: $page");
    final url = '${BASE_URL_COMMUNITIES}api/communities/$communityId/postWithPagination?page=$page&limit=10';
    print("Fetching posts from URL: $url");
    final response = await http.get(
      Uri.parse(url),
    );

    print("@@@@@@@@@@ HTTP response status: ${response.statusCode}");
    print("########## HTTP response body: ${response.body}");

    if (response.statusCode == 200) {
      print("********** Successfully fetched posts for communityId: $communityId, page: $page");
      final data = jsonDecode(response.body);
      print("^^^^^^^^^^ Decoded posts data: $data");
      final List<dynamic> newPosts = data['posts'] ?? [];
      print("&&&&&&&&&& Number of new posts fetched: ${newPosts.length}");
      final Map<String, dynamic> pagination = data['pagination'] ?? {};
      print("(((((((((()))))))))) Pagination info: $pagination");

      final processedPosts = newPosts.map((post) {
        if (post['feedId'] == null) {
          print("!!!!!!!!!! feedId missing for post, setting feedId = _id: ${post['_id']}");
          post['feedId'] = post['_id'];
        }
        return post as Map<String, dynamic>;
      }).toList();

      print("%%%%%%%%%% Processed posts count: ${processedPosts.length}");

      if (mounted) {
        setState(() {
          _posts.addAll(processedPosts);
          _currentPage = pagination['currentPage'] ?? _currentPage;
          _hasNextPage = pagination['hasNextPage'] ?? false;
          _isLoadingMore = false;
          _isFirstLoad = false;
          print("@@@@@@@@@@ State updated after fetching posts. _currentPage: $_currentPage, _hasNextPage: $_hasNextPage, _posts.length: ${_posts.length}");
        });
      } else {
        print("!!!!!!!!!! Widget not mounted, skipping setState for posts");
      }
    } else {
      print("!!!!!!!!!! Failed to load posts, status: ${response.statusCode}");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isFirstLoad = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load posts.')),
        );
      }
      throw Exception('Failed to load community posts');
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
        final wasJoined = isJoined;
        setState(() {
          futureCommunity = fetchCommunity(widget.communityId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                wasJoined ? 'Successfully left the community!' : 'Successfully joined the community!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            backgroundColor: wasJoined ? Colors.red : Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                isJoined ? 'Failed to leave the community.' : 'Failed to join the community.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              child: FutureBuilder<Map<String, dynamic>>(
                future: futureCommunity,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _isFirstLoad) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF7400A5)));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('No community data found.', style: TextStyle(color: Colors.white)));
                  }

                  final communityData = snapshot.data!;

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: CommunityHeader(
                          communityData: communityData,
                          isJoined: isJoined,
                          onJoinPressed: _joinOrLeaveCommunity,
                          refreshPostsCallback: _fetchInitialPosts,
                        ),
                      ),
                      if (_isFirstLoad)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF7400A5)),
                          ),
                        )
                      else if (_posts.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(
                              child: Text(
                                'No posts found.',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => PostWidget(
                              post: _posts[index],
                              refreshPostsCallback: _fetchInitialPosts,
                            ),
                            childCount: _posts.length,
                          ),
                        ),
                      if (_isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF7400A5)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityHeader extends StatefulWidget {
  final Map<String, dynamic> communityData;
  final bool isJoined;
  final VoidCallback onJoinPressed;
  final VoidCallback refreshPostsCallback;

  const CommunityHeader({
    Key? key,
    required this.communityData,
    required this.isJoined,
    required this.onJoinPressed,
    required this.refreshPostsCallback,
  }) : super(key: key);

  @override
  State<CommunityHeader> createState() => _CommunityHeaderState();
}

class _CommunityHeaderState extends State<CommunityHeader> {
  late bool _isJoined;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.isJoined;
  }

  @override
  void didUpdateWidget(CommunityHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isJoined != widget.isJoined) {
      setState(() {
        _isJoined = widget.isJoined;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int memberCount = widget.communityData['memberCount'] ?? 0;
    final List<dynamic> memberDetails = widget.communityData['memberDetails'] ?? [];

    return Column(
      children: [
        Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.all(12.0.w),
                  child: Container(
                    height: 160.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.communityData['backgroundImage'] ?? 'https://via.placeholder.com/500x120'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30.sp,
                      backgroundImage: widget.communityData['profilePicture'] != null ? NetworkImage(widget.communityData['profilePicture']) : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Text(
                    widget.communityData['name'] ?? 'Sports',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7400A5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text('Posts', style: TextStyle(color: Colors.grey)),
                          Text((widget.communityData['postCount'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(width: 30),
                      InkWell(
                        onTap: () => _showMembersModal(context, memberDetails, widget.communityData["_id"]),
                        child: Column(
                          children: [
                            const Text('Members', style: TextStyle(color: Colors.grey)),
                            Text(memberCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isJoined)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostScreen(
                              communityId: widget.communityData['_id'],
                            ),
                          ),
                        ).then((_) {
                          widget.refreshPostsCallback();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400A5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Post', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  if (_isJoined) const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: widget.onJoinPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isJoined ? Colors.red : const Color(0xFF7400A5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    child: Text(
                      _isJoined ? 'Leave' : 'Join',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ReadMoreText(
                widget.communityData['description'] ?? 'No bio available.',
                trimLines: 2,
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
                colorClickableText: const Color(0xFF7400A5),
                trimMode: TrimMode.Line,
                trimCollapsedText: ' Read More',
                trimExpandedText: ' Show Less',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMembersModal(BuildContext context, List<dynamic> memberDetails, String communityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembersScreen(
          communityId: communityId,
        ),
      ),
    );
  }
}

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback refreshPostsCallback;

  const PostWidget({
    Key? key,
    required this.post,
    required this.refreshPostsCallback,
  }) : super(key: key);

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  int _currentMediaIndex = 0;

  String decodeHtml(String input) {
    return parse(input).documentElement?.text ?? input;
  }

  void _handleComment(BuildContext context) {
    try {
      final postObj = Post.fromJson(widget.post);
      Navigator.push(context, MaterialPageRoute(builder: (context) => CommentScreen(post: postObj)));
    } catch (e) {
      log("Error creating Post object for comment: $e");
      log("Post data: ${widget.post}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final mediaList = (widget.post['data']?['media'] as List?) ?? [];

    final profilePicUrl = widget.post['profilePic']?.toString() ?? '';
    final authorName = widget.post['name']?.toString() ?? 'User';
    final authorId = widget.post['author']?.toString() ?? '';

    final profilePicImageProvider = (widget.post['isAnonymous'] == true || profilePicUrl.isEmpty) ? const AssetImage('assets/images/anonymous.png') as ImageProvider : NetworkImage(profilePicUrl);

    String timeAgo = "just now";
    if (widget.post['createdAt'] != null) {
      try {
        if (widget.post['createdAt'] is int) {
          timeAgo = timeago.format(DateTime.fromMillisecondsSinceEpoch(widget.post['createdAt']));
        } else if (widget.post['createdAt'] is String) {
          timeAgo = timeago.format(DateTime.parse(widget.post['createdAt']));
        }
      } catch (e) {
        log("Error parsing time: ${e.toString()}");
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostDetailsScreen(
              postId: widget.post['_id'],
              initialData: widget.post,
              communityData: widget.post['community'] ?? {},
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF7400A5), width: 1),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: profilePicImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post["isAnonymous"] ? 'Anonymous' : authorName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        if (widget.post['community']?['name'] != null)
                          Text(
                            'Posted in ${widget.post['community']['name']}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (authorId.trim() == userProvider.userId?.trim())
                    PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditPostScreen(
                                          postId: widget.post['_id'],
                                          currentCaption: widget.post['data']['content'] ?? '',
                                          isAnonymous: widget.post['isAnonymous'] ?? false,
                                          communityId: widget.post['communityId'] ?? '',
                                          imageUrl: mediaList.isNotEmpty ? mediaList[0]['url'] : '',
                                        ))).then((didUpdate) {
                              if (didUpdate == true) {
                                widget.refreshPostsCallback();
                              }
                            });
                          } else if (value == 'delete') {
                            await deletePost(context: context, postId: widget.post['_id'], userid: userProvider.userId!, token: userProvider.userToken!, communityId: widget.post['communityId'] ?? '').then((_) => widget.refreshPostsCallback());
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ])
                ],
              ),
            ),
            if (widget.post['data']?['content'] != null && widget.post['data']['content'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ReadMoreText(
                  decodeHtml(widget.post['data']['content']),
                  trimLines: 2,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  colorClickableText: const Color(0xFF7400A5),
                  trimMode: TrimMode.Line,
                ),
              ),
            if (mediaList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: mediaList.length > 1
                    ? Stack(
                        alignment: Alignment.topRight,
                        children: [
                          CarouselSlider.builder(
                            itemCount: mediaList.length,
                            options: CarouselOptions(
                              height: 350,
                              enableInfiniteScroll: false,
                              viewportFraction: 1.0,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _currentMediaIndex = index;
                                });
                              },
                            ),
                            itemBuilder: (context, index, realIndex) {
                              final media = mediaList[index];
                              final url = media['url'] ?? '';
                              final isVideo = (media['type'] ?? 'image') == 'video';
                              return isVideo
                                  ? MediaKitVideoPlayer(
                                      url: url,
                                      shouldPlay: index == _currentMediaIndex,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFF7400A5))),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    );
                            },
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentMediaIndex + 1}/${mediaList.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      )
                    : Builder(
                        builder: (context) {
                          final media = mediaList.first;
                          final url = media['url'] ?? '';
                          final isVideo = (media['type'] ?? 'image') == 'video';
                          return SizedBox(
                            height: 350,
                            width: double.infinity,
                            child: isVideo
                                ? MediaKitVideoPlayer(url: url, shouldPlay: true)
                                : CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFF7400A5))),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                          );
                        },
                      ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _handleComment(context),
                    child: SvgPicture.asset('assets/icons/comment-dark.svg', height: 26),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post['commentCount'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  if (userProvider.userId != null) ReactionButton(entityId: widget.post['_id'], entityType: "feed", userId: userProvider.userId!, token: userProvider.userToken!),
                  const SizedBox(width: 8),
                  IconButton(
                      onPressed: () {
                        try {
                          final postObj = Post.fromJson(widget.post);
                          showChatRoomSheet(context, postObj);
                        } catch (e) {
                          log("Error creating Post object for chat sheet: $e");
                          log("Post data: ${widget.post}");
                        }
                      },
                      icon: const Icon(Icons.send, color: Colors.white)),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
