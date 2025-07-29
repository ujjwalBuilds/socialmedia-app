import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';

class PostsProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;
  int _currentPage = 1;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;

  // Getters
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get hasMorePosts => _hasMorePosts;
  bool get isLoadingMore => _isLoadingMore;

  // Check if data is stale (older than 5 minutes)
  bool get isDataStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!).inMinutes > 5;
  }

  // Initialize with empty posts
  PostsProvider() {
    _posts = [];
    _isLoading = true;
    _hasError = false;
  }

  void resetPosts() {
  _posts = [];
  _hasMorePosts = true;
  _currentPage = 1;
  _isLoading = true;
  _isLoadingMore = false;
  notifyListeners();
}


  // Method to fetch posts from API
  Future<void> fetchPosts(String userId, String token, {bool forceRefresh = false, bool loadMore = false}) async {
    // If loading more, use the current page + 1
    if (loadMore) {
      if (!_hasMorePosts || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      notifyListeners();
    } else {
      // If not loading more and data is already loaded and not stale, and we're not forcing a refresh, return
      if (_posts.isNotEmpty && !isDataStale && !forceRefresh) {
        return;
      }
      
      // Reset pagination when refreshing
      if (forceRefresh) {
        _currentPage = 1;
        _hasMorePosts = true;
      }
      
      _isLoading = true;
      _hasError = false;
      notifyListeners();
    }

      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-home-posts?page=$_currentPage'),
        headers: {
          'userId': userId,
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        final List<Post> newPosts = (data['posts'] as List).map((post) => Post.fromJson(post)).toList();
        
        // Check if we have more posts to load
        _hasMorePosts = newPosts.isNotEmpty;
        
        if (loadMore) {
          // Append new posts to existing ones
          _posts.addAll(newPosts);
        } else {
          // Replace existing posts with new ones
          _posts = newPosts;
        }

        _lastFetchTime = DateTime.now();
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = 'Server error: ${response.statusCode}';
        notifyListeners();
      }

  }

  // Update a post (for likes, comments, etc.)
  void updatePost(Post updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  // Update comment count for a post
  void updateCommentCount(String postId, int newCount) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      _posts[index].commentcount = newCount;
      notifyListeners();
    }
  }

  // Remove a post (for post deletion)
  void removePost(String postId) {
    _posts.removeWhere((post) => post.id == postId);
    notifyListeners();
  }

  // Clear posts data (useful for logout)
  void clearPosts() {
    _posts = [];
    _lastFetchTime = null;
    _currentPage = 1;
    _hasMorePosts = true;
    notifyListeners();
  }
}
