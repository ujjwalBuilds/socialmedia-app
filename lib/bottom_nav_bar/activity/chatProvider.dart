import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> _filteredChatRooms = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatRoom> get filteredChatRooms => _filteredChatRooms;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Filter chat rooms based on search query
  void filterChatRooms(String searchQuery) {
    if (searchQuery.isEmpty) {
      _filteredChatRooms = List.from(_chatRooms);
    } else {
      final query = searchQuery.toLowerCase().trim();
      _filteredChatRooms = _chatRooms.where((room) {
        if (room.roomType == 'dm') {
          return room.participants.any((participant) =>
              participant.name?.toLowerCase().contains(query) ?? false);
        } else if (room.roomType == 'group') {
          return room.groupName?.toLowerCase().contains(query) ?? false;
        }
        return false;
      }).toList();
    }
    notifyListeners();
  }

  // Get direct message count
  int getDMCount() {
    return _chatRooms.where((room) => room.roomType == 'dm').length;
  }

  // Get group count
  int getGroupCount() {
    return _chatRooms.where((room) => room.roomType == 'group').length;
  }

  // Fetch chat rooms from API
  Future<void> fetchChatRooms() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String? userid = prefs.getString('user_id');
    String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
        headers: {
          'userId': userid!,
          'token': token!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _chatRooms = (data['chatRooms'] as List)
            .map((room) => ChatRoom.fromJson(room))
            .toList();

        _filteredChatRooms = List.from(_chatRooms);
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching chat rooms: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset the provider state
  void reset() {
    _isInitialized = false;
    _chatRooms = [];
    _filteredChatRooms = [];
    notifyListeners();
  }

  void addNewChatRoom(ChatRoom newChatRoom) {
    if (!_chatRooms.any((room) => room.id == newChatRoom.id)) {
      _chatRooms.insert(0, newChatRoom);
      _filteredChatRooms = List.from(_chatRooms);
      notifyListeners();
    }
  }

  Future<void> refreshChatRooms() async {
    return fetchChatRooms();
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userid = prefs.getString('user_id');
      String? token = prefs.getString('user_token');

      if (userid == null || token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-chat'),
        headers: {
          'userId': userid,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'chatRoomId': chatId}),
      );

      if (response.statusCode == 200) {
        _chatRooms.removeWhere((room) => room.id == chatId);
        _filteredChatRooms.removeWhere((room) => room.id == chatId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}
