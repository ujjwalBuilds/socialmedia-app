import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'community.dart';

class CommunityService with ChangeNotifier {
  late SharedPreferences prefs;
  String? token;

  CommunityService() {
    _initPrefs();
  }
  List<Community> _communities = [];
  int _communityCount = 0;
  bool isLoading = false;

  List<Community> get communities => _communities;
  int get communityCount => _communityCount;

  Future<void> fetchUserCommunities(String userId) async {
    if (userId.isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';

      // Set headers with authorization token
      final headers = {
        'token': token,
        'userid': userId,
        'Content-Type': 'application/json',
      };

      // First fetch the user profile to get community IDs
      final Uri profileUrl = Uri.parse('${BASE_URL}api/showProfile?other=$userId');
      final profileResponse = await http.get(
        profileUrl,
        headers: headers,
      );

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        final communityIds = List<String>.from(profileData['result'][0]['communities'] ?? []);

        // Set the community count immediately
        _communityCount = communityIds.length;

        if (communityIds.isEmpty) {
          _communities = [];
          isLoading = false;
          notifyListeners();
          return;
        }

        // Now fetch details for each community
        List<Community> fetchedCommunities = [];
        for (String communityId in communityIds) {
          await _fetchCommunityInfo(communityId, headers, fetchedCommunities);
        }

        _communities = fetchedCommunities;
        isLoading = false;
        notifyListeners();
      } else {
        print('Error: ${profileResponse.statusCode} - ${profileResponse.body}');
        _communities = [];
        _communityCount = 0;
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching communities: $e');
      _communities = [];
      _communityCount = 0;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCommunityInfo(String communityId, Map<String, String> headers, List<Community> fetchedCommunities) async {
    try {
      final Uri communityUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId');
      final communityResponse = await http.get(
        communityUrl,
        headers: headers,
      );

      if (communityResponse.statusCode == 200) {
        final communityData = json.decode(communityResponse.body);
        fetchedCommunities.add(Community.fromJson(communityData));
      } else {
        print('Error fetching community $communityId: ${communityResponse.statusCode} - ${communityResponse.body}');
      }
    } catch (e) {
      print('Error fetching community $communityId: $e');
    }
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('user_token');
  }

  static const String url = '${BASE_URL_COMMUNITIES}api/communities';
  static Future<List<Community>> fetchCommunities() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> communitiesJson = jsonResponse['communities'];
      return communitiesJson.map((json) => Community.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load communities');
    }
  }

  Future<bool> joinOrLeaveCommunity(String userId, dynamic communityIds, String action) async {
    if (token == null) {
      await _initPrefs();
    }

    final url = Uri.parse('${BASE_URL_COMMUNITIES}api/users/joincommunity');
    final headers = {
      'Content-Type': 'application/json',
      'userId': userId,
      if (token != null) 'token': token!,
    };

    final body = jsonEncode({
      'communityIds': communityIds, // Supports single or multiple community IDs
      'userId': userId,
      'action': action, // Use the passed action parameter
    });

    print(userId);
    print('*******************');

    print(token);
    print('################@@@@@@@@@@@@@@@@@@@@@@@@@@@@');

    print(communityIds);
    print('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');

    try {
      print(url);
      print(headers);
      print(body);
      final response = await http.post(url, headers: headers, body: body);
      // print(token);

      print(response);

      if (response.statusCode == 200) {
        print('Successfully performed action: $action');
        return true; // Return true on success
      } else {
        print('Failed to perform action: $action. Status code: ${response.statusCode}');
        return false; // Return false on failure
      }
    } catch (e) {
      print(token);
      print('An error occurred: $e');
      return false; // Return false on exception
    }
  }

  Future<bool> joinMultipleCommunities(String userId, List<String> communityIds) async {
    if (token == null) {
      await _initPrefs();
    }

    final url = Uri.parse('${BASE_URL_COMMUNITIES}api/users/joinmultiplecommunities');
    final headers = {
      'Content-Type': 'application/json',
      'userId': userId,
      if (token != null) 'token': token!,
      'Authorization': 'Basic Og==',
    };

    final body = jsonEncode({'userId': userId, 'communityIds': communityIds, 'action': 'join'});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('Successfully joined multiple communities');
        return true;
      } else {
        print('Failed to join multiple communities. Status code: ${response.body}');
        print('Failed to join communities. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('An error occurred: $e');
      return false;
    }
  }

  // Future<List<Community>> fetchUserCommunities(String userId) async {
  //   final url = Uri.parse('${BASE_URL_COMMUNITIES}api/users/$userId');
  //   print('Fetching communities from URL: $url');

  //   try {
  //     final response = await http.get(url);
  //     print('Response status code: ${response.statusCode}');
  //     print('Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       print('Decoded data: $data');

  //       if (data['communities'] != null && data['communities'] is List) {
  //         final communities = (data['communities'] as List).map((community) => Community.fromJson(community)).toList();
  //         print('Parsed communities: $communities');
  //         return communities;
  //       } else {
  //         print('No communities found in the response');
  //       }
  //     } else {
  //       print('Failed to fetch communities. Status code: ${response.statusCode}');
  //     }

  //     return [];
  //   } catch (e) {
  //     print('Error fetching communities: $e');
  //     return [];
  //   }
  // }
}
