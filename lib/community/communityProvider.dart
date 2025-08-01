// import 'package:flutter/material.dart';
// import 'package:socialmedia/community/communityApiService.dart';
// import 'package:socialmedia/community/communityModel.dart';

// class CommunityProvider with ChangeNotifier {
//   List<Community> _communities = [];
//   bool _isLoading = false;

//   List<Community> get communities => _communities;
//   bool get isLoading => _isLoading;

//   // Future<void> fetchUserCommunities(String userId) async {
//   //   _isLoading = true;
//   //   notifyListeners();

//   //   try {
//   //     final communityService = CommunityService();
//   //    // _communities = await communityService.fetchUserCommunities(userId);
//   //   } catch (e) {
//   //     print('Error in provider: $e');
//   //   } finally {
//   //     _isLoading = false;
//   //     notifyListeners();
//   //   }
//   // }
// }

// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/community/communityModel.dart';
// import 'package:socialmedia/utils/constants.dart';

// class CommunityProvider with ChangeNotifier {
//   List<Community> _communities = [];
//   bool isLoading = false;

//   List<Community> get communities => _communities;

//   Future<void> fetchUserCommunities(String userId) async {
//     if (userId.isEmpty) return;

//     isLoading = true;
//     notifyListeners();

//     try {
//       // Get token from SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('user_token') ?? '';

//       // Set headers with authorization token
//       final headers = {
//         'token': token,
//         'userid': userId,
//         'Content-Type': 'application/json',
//       };

//       // First fetch the user profile to get community IDs
//       final Uri profileUrl = Uri.parse('${BASE_URL}api/showProfile?other=$userId');
//       final profileResponse = await http.get(
//         profileUrl,
//         headers: headers,
//       );

//       if (profileResponse.statusCode == 200) {
//         final profileData = json.decode(profileResponse.body);
//         final communityIds = List<String>.from(profileData['result'][0]['communities'] ?? []);

//         if (communityIds.isEmpty) {
//           _communities = [];
//           isLoading = false;
//           notifyListeners();
//           return;
//         }

//         // Now fetch details for each community
//         List<Community> fetchedCommunities = [];
//         for (String communityId in communityIds) {
//           await _fetchCommunityInfo(communityId, headers, fetchedCommunities);
//         }

//         _communities = fetchedCommunities;
//         isLoading = false;
//         notifyListeners();
//       } else {
//         print('Error: ${profileResponse.statusCode} - ${profileResponse.body}');
//         _communities = [];
//         isLoading = false;
//         notifyListeners();
//       }
//     } catch (e) {
//       print('Error fetching communities: $e');
//       _communities = [];
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _fetchCommunityInfo(String communityId, Map<String, String> headers, List<Community> fetchedCommunities) async {
//     try {
//       final Uri communityUrl = Uri.parse('https://anco-way-admin-dashboard.vercel.app/api/communities/$communityId');
//       final communityResponse = await http.get(
//         communityUrl,
//         headers: headers,
//       );

//       if (communityResponse.statusCode == 200) {
//         final communityData = json.decode(communityResponse.body);
//         fetchedCommunities.add(Community.fromJson(communityData));
//       } else {
//         print('Error fetching community $communityId: ${communityResponse.statusCode} - ${communityResponse.body}');
//       }
//     } catch (e) {
//       print('Error fetching community $communityId: $e');
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/utils/constants.dart';

class CommunityProvider with ChangeNotifier {
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
        // Get the members array and calculate its length
        List<dynamic> membersList = communityData['members'] ?? [];
        communityData['membersCount'] = membersList.length;
        debugPrint("DEBUG Data: ${communityData.toString()}");
        fetchedCommunities.add(Community.fromJson(communityData));
      } else {
        print('Error fetching community $communityId: ${communityResponse.statusCode} - ${communityResponse.body}');
      }
    } catch (e) {
      print('Error fetching community $communityId: $e');
    }
  }
}
