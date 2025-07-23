import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> users = [];
  List<dynamic> suggestedFriends = [];
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
  }

  Future<void> _fetchSuggestedFriends() async {
    try {
      final response = await _apiService.makeRequest(
        path: 'api/getAllUsers',
        method: 'GET',
      );

      setState(() {
        suggestedFriends = response['users'] ?? [];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _initializeApiService() async {
    try {
      await _apiService.initialize();
      await _fetchSuggestedFriends();
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => users = []);
      return;
    }

    try {
      final response = await _apiService.makeRequest(
        path: 'api/search',
        method: 'POST',
        body: {
          'searchString': query
        },
      );

      setState(() {
        users = response['users'] ?? [];
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'An error occurred',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeApiService,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.roboto(
          color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black
        ),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: GoogleFonts.roboto(
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[300] 
              : Colors.grey[800]
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: (){
            setState(() {
              _searchController.clear();
              users = [];
            });
          }, icon: Icon(Icons.clear ,color: Colors.grey,)) : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.grey[300],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(45),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedFriends() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestedFriends.length,
        itemBuilder: (context, index) {
          final user = suggestedFriends[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: user['profilePic'] != null ? NetworkImage(user['profilePic']) : const AssetImage('assets/avatar/4.png') as ImageProvider,
            ),
            title: Text(
              user['name'] ?? 'Anonymous',
              style: GoogleFonts.roboto(
                fontSize: 14.0,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: user['_id'])));
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 8.0.h),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: user['profilePic'] != null ? NetworkImage(user['profilePic']) : NetworkImage(user['avatar']),
                radius: 25.sp,
              ),
              title: Text(
                overflow: TextOverflow.ellipsis,
                user['name'] ?? 'Unknown',
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: user['id'])));
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard when tapping outside
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black 
            : Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0, top: 8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildSearchField(),
                if (_searchController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 10),
                    child: Text(
                      'Suggested Friends',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      ),
                    ),
                  ),
                if (_searchController.text.isEmpty)
                  _buildSuggestedFriends(),
                if (_searchController.text.isNotEmpty)
                  _isLoading
                    ? _buildLoadingWidget()
                    : _error != null
                      ? _buildErrorWidget()
                      : users.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'No user found',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                ),
                              ),
                            ),
                          )
                        : _buildSearchResults(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}