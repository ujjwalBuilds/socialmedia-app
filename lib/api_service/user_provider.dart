import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class UserProviderall with ChangeNotifier {
  String? _userId;
  String? _userToken;
  String? _socketToken;
  String? _userName;
  String? _userprofile;
  int? _publicStatus;
  bool _isPrivate = false;
  String? _profilePic;
  String? _avatar;

  String? get userId => _userId;
  String? get userToken => _userToken;
  String? get socketToken => _socketToken;
  String? get userName => _userName;
  String? get userProfile => _userprofile;
  int? get publicStatus => _publicStatus;
  bool get isPrivate => _isPrivate;
  String? get profilePic => _profilePic;
  String? get avatar => _avatar;

  set userName(String? value) {
    _userName = value;
    notifyListeners();
  }

  set userProfile(String? value) {
    _userprofile = value;
    notifyListeners();
  }

  Future<void> refreshUserProfile(String userId, String token) async {
    try {
      final Uri url = Uri.parse('${BASE_URL}api/showProfile?other=$userId');
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'userid': userId,
        'token': token,
      };

      final http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['result'] != null &&
            responseData['result'] is List &&
            responseData['result'].isNotEmpty) {
          final userDetails = responseData['result'][0];
          updateProfilePic(userDetails['profilePic']);
        }
      }
    } catch (error) {
      print('An error occurred while fetching profile: $error');
    }
  }

  void updateProfilePic(String? pic) {
    _profilePic = pic;
    notifyListeners();
  }

  void updatePrivacyState(bool isPrivate) {
    _isPrivate = isPrivate;
    notifyListeners();
  }

  void updateProfilePicture(String? newProfilePicture) {
    _userprofile = newProfilePicture;
    notifyListeners();
  }

  /// Save user data in SharedPreferences and update provider state
  Future<void> saveUserData(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _userToken = data['token'];
    _userId = data['userDetails']['_id'];
    _socketToken = data['socketToken'];
    _userName = data['userDetails']['name'];
    _userprofile = data['userDetails']['profilePic'];
    _profilePic = data['userDetails']['profilePic'];

    await prefs.setString('user_token', _userToken!);
    await prefs.setString('user_id', _userId!);
    await prefs.setString('socketToken', _socketToken!);
    await prefs.setString('user_name', _userName!);
    await prefs.setString('user_profile', _userprofile!);

    notifyListeners(); // Notify UI to rebuild
  }

  /// Load user data from SharedPreferences
  Future<void> loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userToken = prefs.getString('user_token');
    _userId = prefs.getString('user_id');
    _socketToken = prefs.getString('socketToken');
    _userName = prefs.getString('user_name');
    _userprofile = prefs.getString('user_profile');
    _profilePic = prefs.getString('user_profile');

    notifyListeners();
  }

  void setPublicStatus(int status) {
    _publicStatus = status;
    notifyListeners();
  }

  /// Clear user data (for logout)
  Future<void> clearUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _userToken = null;
    _userId = null;
    _socketToken = null;
    _userName = null;
    _userprofile = null;
    _profilePic = null;

    notifyListeners();
  }

  void updateAvatar(String? avatar) {
    _avatar = avatar;
    notifyListeners();
  }

  String? getCurrentProfilePicture() {
    if (_isPrivate) {
      return _avatar;
    } else {
      return _profilePic?.isNotEmpty == true ? _profilePic : _avatar;
    }
  }
}
