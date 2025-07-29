import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/customappbar.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/story_section.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExplorePage extends StatefulWidget {
  final bool forceRefresh;
  const ExplorePage({super.key, this.forceRefresh = false});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with RouteAware {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  String? userId;
  String? token;
  bool isLoading = true;
  final GlobalKey<StorySectionState> _storySectionKey =
      GlobalKey<StorySectionState>();

  @override
  void initState() {
    super.initState();
    print('ExplorePage initState called');
    setState(() {
      isLoading = true;
    });
    
    fetchUserDetails().then((_) {
      if (mounted) {
        print('User details fetched, triggering refresh');
        // After user details are fetched, explicitly trigger post loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).unfocus();
          _refreshData();
        });
      }
    });
  }

  @override
  void didUpdateWidget(ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ExplorePage didUpdateWidget called');
    print('Old forceRefresh: ${oldWidget.forceRefresh}');
    print('New forceRefresh: ${widget.forceRefresh}');
    print('Widget key: ${widget.key}');
    print('Old widget key: ${oldWidget.key}');
    
    if (widget.forceRefresh && !oldWidget.forceRefresh) {
      print('Force refresh triggered due to forceRefresh change');
      _refreshData(force: true);
    } else if (widget.key != oldWidget.key) {
      print('Force refresh triggered due to key change');
      _refreshData(force: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page
    _refreshData();
  }

  // Add this method to handle data refresh
  Future<void> _refreshData({bool force = false}) async {
    print('_refreshData called with force: $force');
    if (userId != null && token != null) {
      print('Refreshing data with userId: $userId');
      setState(() {
        isLoading = true;
      });

      try {
        final postsProvider = Provider.of<PostsProvider>(context, listen: false);
        await postsProvider.fetchPosts(userId!, token!, forceRefresh: force);
        print('Posts fetched successfully');

        // Call story methods without awaiting their void return
        if (_storySectionKey.currentState != null) {
          _storySectionKey.currentState!.fetchStories();
          _storySectionKey.currentState!.checkForStories();
        }
      } catch (e) {
        print('Error refreshing data: $e');
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      print('Cannot refresh: userId or token is null');
    }
  }

  void _onRefresh() async {
    await _refreshData(force: true);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (userId != null && token != null) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);

      // Only load more if we have more posts to load
      if (postsProvider.hasMorePosts && !postsProvider.isLoadingMore) {
        await postsProvider.fetchPosts(userId!, token!, loadMore: true);
      }
    }

    _refreshController.loadComplete();
  }

  Future<void> fetchUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final fetchedUserId = prefs.getString('user_id');
    final fetchedToken = prefs.getString('user_token');

    if (fetchedUserId != null && fetchedToken != null) {
      setState(() {
        userId = fetchedUserId;
        token = fetchedToken;
        isLoading = false;
      });

      // Initialize the posts provider with user data
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      await postsProvider.fetchPosts(fetchedUserId, fetchedToken);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        appBar: CustomAppBar(),
        body: Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            if (isLoading && postsProvider.posts.isEmpty) {
              return _buildShimmerPostItem();
            }

            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              enablePullUp: true,
              header: CustomHeader(
                builder: (context, mode) {
                  Widget body;
                  if (mode == RefreshStatus.idle) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.refreshing) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.canRefresh) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else {
                    body = CupertinoActivityIndicator(radius: 14);
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              footer: CustomFooter(
                builder: (context, mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Text("Pull up to load more");
                  } else if (mode == LoadStatus.loading) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == LoadStatus.failed) {
                    body = Text("Load failed! Click retry!");
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text("Release to load more!");
                  } else {
                    body = Text("No more data");
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Story Section will scroll with posts
                  StorySection(
                      userId: userId ?? "0",
                      token: token ?? "0",
                      key: _storySectionKey),
                  const SizedBox(height: 8),
                  // Posts Section
                  ...postsProvider.posts
                      .map((post) => PostCard(post: post))
                      .toList(),
                  // Show message if no more posts
                  if (!postsProvider.hasMorePosts &&
                      postsProvider.posts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Text("No more posts to load")),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading screen widget
  Widget _buildShimmerPostItem() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]!
          : Colors.grey[200]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Profile circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                // Username and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
                Spacer(),
                // More options icon
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Post image
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/customappbar.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/story_section.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExplorePage extends StatefulWidget {
  final bool forceRefresh;
  const ExplorePage({super.key, this.forceRefresh = false});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with RouteAware {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  String? userId;
  String? token;
  bool isLoading = true;
  final GlobalKey<StorySectionState> _storySectionKey =
      GlobalKey<StorySectionState>();

  @override
  void initState() {
    super.initState();
    print('ExplorePage initState called');
    setState(() {
      isLoading = true;
    });
    
    fetchUserDetails().then((_) {
      if (mounted) {
        print('User details fetched, triggering refresh');
        // After user details are fetched, explicitly trigger post loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).unfocus();
          _refreshData();
        });
      }
    });
  }

  @override
  void didUpdateWidget(ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ExplorePage didUpdateWidget called');
    print('Old forceRefresh: ${oldWidget.forceRefresh}');
    print('New forceRefresh: ${widget.forceRefresh}');
    print('Widget key: ${widget.key}');
    print('Old widget key: ${oldWidget.key}');
    
    if (widget.forceRefresh && !oldWidget.forceRefresh) {
      print('Force refresh triggered due to forceRefresh change');
      _refreshData(force: true);
    } else if (widget.key != oldWidget.key) {
      print('Force refresh triggered due to key change');
      _refreshData(force: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page
    _refreshData();
  }

  // Add this method to handle data refresh
  Future<void> _refreshData({bool force = false}) async {
    print('_refreshData called with force: $force');
    if (userId != null && token != null) {
      print('Refreshing data with userId: $userId');
      setState(() {
        isLoading = true;
      });

      try {
        final postsProvider = Provider.of<PostsProvider>(context, listen: false);
        await postsProvider.fetchPosts(userId!, token!, forceRefresh: force);
        print('Posts fetched successfully');

        // Call story methods without awaiting their void return
        if (_storySectionKey.currentState != null) {
          _storySectionKey.currentState!.fetchStories();
          _storySectionKey.currentState!.checkForStories();
        }
      } catch (e) {
        print('Error refreshing data: $e');
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      print('Cannot refresh: userId or token is null');
    }
  }

  void _onRefresh() async {
    await _refreshData(force: true);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (userId != null && token != null) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);

      // Only load more if we have more posts to load
      if (postsProvider.hasMorePosts && !postsProvider.isLoadingMore) {
        await postsProvider.fetchPosts(userId!, token!, loadMore: true);
      }
    }

    _refreshController.loadComplete();
  }

  Future<void> fetchUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final fetchedUserId = prefs.getString('user_id');
    final fetchedToken = prefs.getString('user_token');

    if (fetchedUserId != null && fetchedToken != null) {
      setState(() {
        userId = fetchedUserId;
        token = fetchedToken;
        isLoading = false;
      });

      // Initialize the posts provider with user data
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      await postsProvider.fetchPosts(fetchedUserId, fetchedToken);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        appBar: CustomAppBar(),
        body: Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            if (isLoading && postsProvider.posts.isEmpty) {
              return _buildShimmerPostItem();
            }

            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              enablePullUp: true,
              header: CustomHeader(
                builder: (context, mode) {
                  Widget body;
                  if (mode == RefreshStatus.idle) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.refreshing) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.canRefresh) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else {
                    body = CupertinoActivityIndicator(radius: 14);
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              footer: CustomFooter(
                builder: (context, mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Text("Pull up to load more");
                  } else if (mode == LoadStatus.loading) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == LoadStatus.failed) {
                    body = Text("Load failed! Click retry!");
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text("Release to load more!");
                  } else {
                    body = Text("No more data");
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Story Section will scroll with posts
                  StorySection(
                      userId: userId ?? "0",
                      token: token ?? "0",
                      key: _storySectionKey),
                  const SizedBox(height: 8),
                  // Posts Section
                  ...postsProvider.posts
                      .map((post) => PostCard(post: post))
                      .toList(),
                  // Show message if no more posts
                  if (!postsProvider.hasMorePosts &&
                      postsProvider.posts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Text("No more posts to load")),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading screen widget
  Widget _buildShimmerPostItem() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]!
          : Colors.grey[200]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Profile circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                // Username and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
                Spacer(),
                // More options icon
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Post image
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/customappbar.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/story_section.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExplorePage extends StatefulWidget {
  final bool forceRefresh;
  const ExplorePage({super.key, this.forceRefresh = false});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with RouteAware {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  String? userId;
  String? token;
  bool isLoading = true;
  final GlobalKey<StorySectionState> _storySectionKey =
      GlobalKey<StorySectionState>();

  @override
  void initState() {
    super.initState();
    print('ExplorePage initState called');
    setState(() {
      isLoading = true;
    });
    
    fetchUserDetails().then((_) {
      if (mounted) {
        print('User details fetched, triggering refresh');
        // After user details are fetched, explicitly trigger post loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).unfocus();
          _refreshData();
        });
      }
    });
  }

  @override
  void didUpdateWidget(ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ExplorePage didUpdateWidget called');
    print('Old forceRefresh: ${oldWidget.forceRefresh}');
    print('New forceRefresh: ${widget.forceRefresh}');
    print('Widget key: ${widget.key}');
    print('Old widget key: ${oldWidget.key}');
    
    if (widget.forceRefresh && !oldWidget.forceRefresh) {
      print('Force refresh triggered due to forceRefresh change');
      _refreshData(force: true);
    } else if (widget.key != oldWidget.key) {
      print('Force refresh triggered due to key change');
      _refreshData(force: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page
    _refreshData();
  }

  // Add this method to handle data refresh
  Future<void> _refreshData({bool force = false}) async {
    print('_refreshData called with force: $force');
    if (userId != null && token != null) {
      print('Refreshing data with userId: $userId');
      setState(() {
        isLoading = true;
      });

      try {
        final postsProvider = Provider.of<PostsProvider>(context, listen: false);
        await postsProvider.fetchPosts(userId!, token!, forceRefresh: force);
        print('Posts fetched successfully');

        // Call story methods without awaiting their void return
        if (_storySectionKey.currentState != null) {
          _storySectionKey.currentState!.fetchStories();
          _storySectionKey.currentState!.checkForStories();
        }
      } catch (e) {
        print('Error refreshing data: $e');
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      print('Cannot refresh: userId or token is null');
    }
  }

  void _onRefresh() async {
    await _refreshData(force: true);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (userId != null && token != null) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);

      // Only load more if we have more posts to load
      if (postsProvider.hasMorePosts && !postsProvider.isLoadingMore) {
        await postsProvider.fetchPosts(userId!, token!, loadMore: true);
      }
    }

    _refreshController.loadComplete();
  }

  Future<void> fetchUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final fetchedUserId = prefs.getString('user_id');
    final fetchedToken = prefs.getString('user_token');

    if (fetchedUserId != null && fetchedToken != null) {
      setState(() {
        userId = fetchedUserId;
        token = fetchedToken;
        isLoading = false;
      });

      // Initialize the posts provider with user data
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      await postsProvider.fetchPosts(fetchedUserId, fetchedToken);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        appBar: CustomAppBar(),
        body: Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            if (isLoading && postsProvider.posts.isEmpty) {
              return _buildShimmerPostItem();
            }

            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              enablePullUp: true,
              header: CustomHeader(
                builder: (context, mode) {
                  Widget body;
                  if (mode == RefreshStatus.idle) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.refreshing) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.canRefresh) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else {
                    body = CupertinoActivityIndicator(radius: 14);
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              footer: CustomFooter(
                builder: (context, mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Text("Pull up to load more");
                  } else if (mode == LoadStatus.loading) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == LoadStatus.failed) {
                    body = Text("Load failed! Click retry!");
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text("Release to load more!");
                  } else {
                    body = Text("No more data");
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Story Section will scroll with posts
                  StorySection(
                      userId: userId ?? "0",
                      token: token ?? "0",
                      key: _storySectionKey),
                  const SizedBox(height: 8),
                  // Posts Section
                  ...postsProvider.posts
                      .map((post) => PostCard(post: post))
                      .toList(),
                  // Show message if no more posts
                  if (!postsProvider.hasMorePosts &&
                      postsProvider.posts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Text("No more posts to load")),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading screen widget
  Widget _buildShimmerPostItem() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]!
          : Colors.grey[200]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Profile circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                // Username and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
                Spacer(),
                // More options icon
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Post image
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/customappbar.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/story_section.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExplorePage extends StatefulWidget {
  final bool forceRefresh;
  const ExplorePage({super.key, this.forceRefresh = false});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with RouteAware {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  String? userId;
  String? token;
  bool isLoading = true;
  final GlobalKey<StorySectionState> _storySectionKey =
      GlobalKey<StorySectionState>();

  @override
  void initState() {
    super.initState();
    print('ExplorePage initState called');
    setState(() {
      isLoading = true;
    });
    
    fetchUserDetails().then((_) {
      if (mounted) {
        print('User details fetched, triggering refresh');
        // After user details are fetched, explicitly trigger post loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).unfocus();
          _refreshData();
        });
      }
    });
  }

  @override
  void didUpdateWidget(ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ExplorePage didUpdateWidget called');
    print('Old forceRefresh: ${oldWidget.forceRefresh}');
    print('New forceRefresh: ${widget.forceRefresh}');
    print('Widget key: ${widget.key}');
    print('Old widget key: ${oldWidget.key}');
    
    if (widget.forceRefresh && !oldWidget.forceRefresh) {
      print('Force refresh triggered due to forceRefresh change');
      _refreshData(force: true);
    } else if (widget.key != oldWidget.key) {
      print('Force refresh triggered due to key change');
      _refreshData(force: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page
    _refreshData();
  }

  // Add this method to handle data refresh
  Future<void> _refreshData({bool force = false}) async {
    print('_refreshData called with force: $force');
    if (userId != null && token != null) {
      print('Refreshing data with userId: $userId');
      setState(() {
        isLoading = true;
      });

      try {
        final postsProvider = Provider.of<PostsProvider>(context, listen: false);
        await postsProvider.fetchPosts(userId!, token!, forceRefresh: force);
        print('Posts fetched successfully');

        // Call story methods without awaiting their void return
        if (_storySectionKey.currentState != null) {
          _storySectionKey.currentState!.fetchStories();
          _storySectionKey.currentState!.checkForStories();
        }
      } catch (e) {
        print('Error refreshing data: $e');
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      print('Cannot refresh: userId or token is null');
    }
  }

  void _onRefresh() async {
    await _refreshData(force: true);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (userId != null && token != null) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);

      // Only load more if we have more posts to load
      if (postsProvider.hasMorePosts && !postsProvider.isLoadingMore) {
        await postsProvider.fetchPosts(userId!, token!, loadMore: true);
      }
    }

    _refreshController.loadComplete();
  }

  Future<void> fetchUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final fetchedUserId = prefs.getString('user_id');
    final fetchedToken = prefs.getString('user_token');

    if (fetchedUserId != null && fetchedToken != null) {
      setState(() {
        userId = fetchedUserId;
        token = fetchedToken;
        isLoading = false;
      });

      // Initialize the posts provider with user data
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      await postsProvider.fetchPosts(fetchedUserId, fetchedToken);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        appBar: CustomAppBar(),
        body: Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            if (isLoading && postsProvider.posts.isEmpty) {
              return _buildShimmerPostItem();
            }

            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              enablePullUp: true,
              header: CustomHeader(
                builder: (context, mode) {
                  Widget body;
                  if (mode == RefreshStatus.idle) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.refreshing) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.canRefresh) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else {
                    body = CupertinoActivityIndicator(radius: 14);
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              footer: CustomFooter(
                builder: (context, mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Text("Pull up to load more");
                  } else if (mode == LoadStatus.loading) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == LoadStatus.failed) {
                    body = Text("Load failed! Click retry!");
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text("Release to load more!");
                  } else {
                    body = Text("No more data");
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Story Section will scroll with posts
                  StorySection(
                      userId: userId ?? "0",
                      token: token ?? "0",
                      key: _storySectionKey),
                  const SizedBox(height: 8),
                  // Posts Section
                  ...postsProvider.posts
                      .map((post) => PostCard(post: post))
                      .toList(),
                  // Show message if no more posts
                  if (!postsProvider.hasMorePosts &&
                      postsProvider.posts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Text("No more posts to load")),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading screen widget
  Widget _buildShimmerPostItem() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]!
          : Colors.grey[200]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Profile circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                // Username and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
                Spacer(),
                // More options icon
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Post image
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/customappbar.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/story_section.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExplorePage extends StatefulWidget {
  final bool forceRefresh;
  const ExplorePage({super.key, this.forceRefresh = false});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with RouteAware {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  String? userId;
  String? token;
  bool isLoading = true;
  final GlobalKey<StorySectionState> _storySectionKey =
      GlobalKey<StorySectionState>();

  @override
  void initState() {
    super.initState();
    print('ExplorePage initState called');
    setState(() {
      isLoading = true;
    });
    
    fetchUserDetails().then((_) {
      if (mounted) {
        print('User details fetched, triggering refresh');
        // After user details are fetched, explicitly trigger post loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).unfocus();
          _refreshData();
        });
      }
    });
  }

  @override
  void didUpdateWidget(ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ExplorePage didUpdateWidget called');
    print('Old forceRefresh: ${oldWidget.forceRefresh}');
    print('New forceRefresh: ${widget.forceRefresh}');
    print('Widget key: ${widget.key}');
    print('Old widget key: ${oldWidget.key}');
    
    if (widget.forceRefresh && !oldWidget.forceRefresh) {
      print('Force refresh triggered due to forceRefresh change');
      _refreshData(force: true);
    } else if (widget.key != oldWidget.key) {
      print('Force refresh triggered due to key change');
      _refreshData(force: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page
    _refreshData();
  }

  // Add this method to handle data refresh
  Future<void> _refreshData({bool force = false}) async {
    print('_refreshData called with force: $force');
    if (userId != null && token != null) {
      print('Refreshing data with userId: $userId');
      setState(() {
        isLoading = true;
      });

      try {
        final postsProvider = Provider.of<PostsProvider>(context, listen: false);
        await postsProvider.fetchPosts(userId!, token!, forceRefresh: force);
        print('Posts fetched successfully');

        // Call story methods without awaiting their void return
        if (_storySectionKey.currentState != null) {
          _storySectionKey.currentState!.fetchStories();
          _storySectionKey.currentState!.checkForStories();
        }
      } catch (e) {
        print('Error refreshing data: $e');
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      print('Cannot refresh: userId or token is null');
    }
  }

  void _onRefresh() async {
    await _refreshData(force: true);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (userId != null && token != null) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);

      // Only load more if we have more posts to load
      if (postsProvider.hasMorePosts && !postsProvider.isLoadingMore) {
        await postsProvider.fetchPosts(userId!, token!, loadMore: true);
      }
    }

    _refreshController.loadComplete();
  }

  Future<void> fetchUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final fetchedUserId = prefs.getString('user_id');
    final fetchedToken = prefs.getString('user_token');

    if (fetchedUserId != null && fetchedToken != null) {
      setState(() {
        userId = fetchedUserId;
        token = fetchedToken;
        isLoading = false;
      });

      // Initialize the posts provider with user data
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      await postsProvider.fetchPosts(fetchedUserId, fetchedToken);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        appBar: CustomAppBar(),
        body: Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            if (isLoading && postsProvider.posts.isEmpty) {
              return _buildShimmerPostItem();
            }

            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              enablePullUp: true,
              header: CustomHeader(
                builder: (context, mode) {
                  Widget body;
                  if (mode == RefreshStatus.idle) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.refreshing) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == RefreshStatus.canRefresh) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else {
                    body = CupertinoActivityIndicator(radius: 14);
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              footer: CustomFooter(
                builder: (context, mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Text("Pull up to load more");
                  } else if (mode == LoadStatus.loading) {
                    body = CupertinoActivityIndicator(radius: 14);
                  } else if (mode == LoadStatus.failed) {
                    body = Text("Load failed! Click retry!");
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text("Release to load more!");
                  } else {
                    body = Text("No more data");
                  }
                  return Container(
                    height: 40.0,
                    child: Center(child: body),
                  );
                },
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Story Section will scroll with posts
                  StorySection(
                      userId: userId ?? "0",
                      token: token ?? "0",
                      key: _storySectionKey),
                  const SizedBox(height: 8),
                  // Posts Section
                  ...postsProvider.posts
                      .map((post) => PostCard(post: post))
                      .toList(),
                  // Show message if no more posts
                  if (!postsProvider.hasMorePosts &&
                      postsProvider.posts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Text("No more posts to load")),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading screen widget
  Widget _buildShimmerPostItem() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]!
          : Colors.grey[200]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Profile circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                // Username and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
                Spacer(),
                // More options icon
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Post image
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
