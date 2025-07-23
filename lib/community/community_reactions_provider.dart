import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/utils/constants.dart';

class CommunityReactionsProvider extends ChangeNotifier {
  Map<String, List<ReactionData>> _entityReactions = {};
  Map<String, bool> _loadingStates = {};
  Map<String, String?> _userReactions = {};

  bool isLoadingForEntity(String entityId) {
    return _loadingStates[entityId] ?? false;
  }

  String? getUserReactionForEntity(String entityId) {
    return _userReactions[entityId];
  }

  int getTotalReactionsCount(String entityId) {
    if (!_entityReactions.containsKey(entityId)) return 0;
    return _entityReactions[entityId]!.fold(0, (sum, reaction) => sum + reaction.count);
  }

  List<ReactionData> getReactionsForEntity(String entityId) {
    return _entityReactions[entityId] ?? [];
  }

  Future<void> fetchReactions(String postId, String communityId, String userId, String token) async {
    // Mark as loading
    _loadingStates[postId] = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/$postId/reactions'),
        headers: {
          'token': token,
          'userId': userId,
        },
      );


      log('Response status: ${response.statusCode}' , name: 'fetchReactions');
      log('Response body: ${response.body}' , name: 'fetchReactions');
      log('Response URL: ${BASE_URL_COMMUNITIES}api/communities/$communityId/post/$postId/reactions' , name: 'fetchReactions');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Process reaction data
        List<ReactionData> reactions = [];
        String? userReaction;
        
        // Example structure - adapt based on your actual API response
        if (data['reactionDetails'] != null) {
          // Check if the user has reacted
          if (data['reactionDetails']['reactions'] is List) {
            List<dynamic> reactionsList = data['reactionDetails']['reactions'];
            
            for (var reaction in reactionsList) {
              if (reaction['userId'] == userId) {
                userReaction = reaction['reactionType'];
                break;
              }
            }
          }
          
          // Set the reactions
          _userReactions[postId] = userReaction;
          
          // Initialize with common reaction types
          reactions = [
            ReactionData(type: 'like', count: 0, users: []),
            ReactionData(type: 'love', count: 0, users: []),
            // Add other types as needed
          ];
          
          // Set the total count
          if (data['reactionDetails']['total'] != null) {
            reactions[0].count = data['reactionDetails']['total']; // Assign to like for now
          }
        }
        
        _entityReactions[postId] = reactions;
      } else {
        print('Failed to fetch reactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reactions: $e');
    } finally {
      _loadingStates[postId] = false;
      notifyListeners();
    }
  }

  Future<void> addReaction(String postId, String communityId, String reactionType, String userId, String token) async {
    _loadingStates[postId] = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
        headers: {
          'token': token,
          'userId': userId,
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'postId': postId,
          'reactionType': reactionType,
        }),
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');
      log('Response URL: ${'${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'}');

      log("Sent Body: ${json.encode({
        'postId': postId,
        'reactionType': reactionType,
      })}");

      if (response.statusCode == 200) {
        _userReactions[postId] = reactionType;
        await fetchReactions(postId, communityId, userId, token);
      } else {
        print('Failed to add reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding reaction: $e');
    } finally {
      _loadingStates[postId] = false;
      notifyListeners();
    }
  }

  Future<void> removeReaction(String postId, String communityId, String userId, String token) async {
    _loadingStates[postId] = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post/like'),
        headers: {
          'token': token,
          'userId': userId,
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'postId': postId,
          'reactionType': 'unlike',
        }),
      );

      if (response.statusCode == 200) {
        _userReactions[postId] = null;
        await fetchReactions(postId, communityId, userId, token);
      } else {
        print('Failed to remove reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing reaction: $e');
    } finally {
      _loadingStates[postId] = false;
      notifyListeners();
    }
  }
} 