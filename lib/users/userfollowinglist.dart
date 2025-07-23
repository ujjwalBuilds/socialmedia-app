import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FollowerFollowingScreen extends StatefulWidget {
  final int initialTabIndex;

  const FollowerFollowingScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<FollowerFollowingScreen> createState() => _FollowerFollowingScreenState();
}

class _FollowerFollowingScreenState extends State<FollowerFollowingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Lists to hold data from your API calls
  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  /// Track loading states for each list
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;

  /// For counting how many followers/following
  int _followerCount = 0;
  int _followingCount = 0;

  /// Search text
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize TabController for two tabs
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Fetch both lists
    _fetchFollowers();
    _fetchFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch followers from your API
  Future<void> _fetchFollowers() async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final userId = userProvider.userId;
      final token = userProvider.userToken;

      if (userId == null || token == null) {
        print("User credentials missing");
        setState(() {
          _isLoadingFollowers = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("${BASE_URL}api/followers"),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data["result"] ?? [];
        setState(() {
          _followers = results;
          _followerCount = results.length;
          _isLoadingFollowers = false;
        });
      } else {
        print("Error fetching followers: ${response.statusCode}");
        setState(() {
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      print("Exception fetching followers: $e");
      setState(() {
        _isLoadingFollowers = false;
      });
    }
  }

  /// Fetch following from your API
  Future<void> _fetchFollowing() async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final userId = userProvider.userId;
      final token = userProvider.userToken;

      if (userId == null || token == null) {
        print("User credentials missing");
        setState(() {
          _isLoadingFollowing = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("${BASE_URL}api/followings"),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data["result"] ?? [];
        setState(() {
          _following = results;
          _followingCount = results.length;
          _isLoadingFollowing = false;
        });
      } else {
        print("Error fetching following: ${response.statusCode}");
        setState(() {
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      print("Exception fetching following: $e");
      setState(() {
        _isLoadingFollowing = false;
      });
    }
  }

  /// Filter function for search
  List<dynamic> _filterList(List<dynamic> originalList) {
    if (_searchText.isEmpty) return originalList;
    final lowerSearch = _searchText.toLowerCase();
    return originalList.where((user) {
      final nickname = (user["nickName"] ?? "").toLowerCase();
      return nickname.contains(lowerSearch);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
        body: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SafeArea(
            child: Column(
              children: [
                // Followers/Following counts as tabs
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF7400A5),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(
                      child: Text(
                        "$_followerCount Followers",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        "$_followingCount Following",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                      decoration: InputDecoration(
                        hintText: "Search ",
                        hintStyle: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchText = val;
                        });
                      },
                    ),
                  ),
                ),

                // Tab view content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Followers tab
                      _isLoadingFollowers
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7400A5)))
                          : _buildListView(
                              data: _filterList(_followers),
                              isFollowerTab: true,
                            ),
                      // Following tab
                      _isLoadingFollowing
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7400A5)))
                          : _buildListView(
                              data: _filterList(_following),
                              isFollowerTab: false,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7400A5),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                "Done",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView({
    required List<dynamic> data,
    required bool isFollowerTab,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No users found",
          style: GoogleFonts.roboto(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
        ),
      );
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final user = data[index];
        final nickname = user["name"] ?? "List item";

        return InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: user['_id'])));
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user['profilePic'] == null ? AssetImage('assets/avatar/5.png') : NetworkImage(user['profilePic']),
              backgroundColor: Color(0xFF7400A5),
              radius: 20,
            ),
            title: Text(
              nickname,
              style: GoogleFonts.roboto(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                fontSize: 14,
              ),
            ),
            trailing: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF7400A5), width: 1),
              ),
              child: TextButton(
                onPressed: () async {
                  final userProvider = Provider.of<UserProviderall>(context, listen: false);
                  final userId = userProvider.userId;
                  final token = userProvider.userToken;
                  final otherUserId = user['_id'];

                  if (userId == null || token == null) {
                    print("User credentials missing");
                    return;
                  }

                  try {
                    final url = isFollowerTab ? Uri.parse("${BASE_URL}api/follower/remove") : Uri.parse("${BASE_URL}api/unfollow");

                    // Create FormData request
                    final request = http.MultipartRequest('POST', url);

                    // Add headers
                    request.headers['userId'] = userId;
                    request.headers['token'] = token;

                    // Add form data fields
                    request.fields['otherId'] = otherUserId;

                    // Send the request
                    final response = await request.send();

                    // Convert the stream response to a regular response
                    final responseString = await http.Response.fromStream(response);

                    if (response.statusCode == 200) {
                      // Refresh the relevant list
                      if (isFollowerTab) {
                        _fetchFollowers();
                      } else {
                        _fetchFollowing();
                      }
                      Fluttertoast.showToast(
                        msg: isFollowerTab ? "Follower removed" : "Unfollowed successfully",
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    } else {
                      print("Failed to ${isFollowerTab ? 'remove follower' : 'unfollow'}: ${responseString.body}");
                      Fluttertoast.showToast(
                        msg: "Failed to ${isFollowerTab ? 'remove follower' : 'unfollow'}",
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    }
                  } catch (e) {
                    print("Error ${isFollowerTab ? 'removing follower' : 'unfollowing'}: $e");
                    Fluttertoast.showToast(
                      msg: "Error ${isFollowerTab ? 'removing follower' : 'unfollowing'}",
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(80, 30),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isFollowerTab ? "Remove" : "Unfollow",
                  style: GoogleFonts.roboto(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Color(0xFF7400A5),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );
      },
    );
  }
}
