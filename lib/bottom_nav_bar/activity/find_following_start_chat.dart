import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/chatProvider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/detailed_chat_page.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class FollowingsScreen extends StatefulWidget {
  @override
  _FollowingsScreenState createState() => _FollowingsScreenState();
}

class _FollowingsScreenState extends State<FollowingsScreen> {
  List<Following> _followings = [];
  bool _isLoading = true;
  String? _error;
  late UserProviderall userProvider;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {}); // Refresh UI after loading data
    });
    _fetchFollowings();
  }

  Future<void> _fetchFollowings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${BASE_URL}api/followings'),
        headers: {
          'userId': userId,
          'token': token
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(response.body);
        setState(() {
          _followings = (jsonResponse['result'] as List).map((json) => Following.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load followings');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startChat(String participantId) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/start-message'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
        },
        body: json.encode({
          'userId2': participantId,
        }),
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final chatRoom = ChatRoom.fromJson(jsonResponse['chatRoom']);

        chatProvider.addNewChatRoom(chatRoom);

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DChatScreen(chatRoom: chatRoom)));
      } else {
        throw Exception('Failed to start chat');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        'Error starting chat: ${e.toString()}',
        style: GoogleFonts.roboto(),
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Followings', style: GoogleFonts.roboto()),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: GoogleFonts.roboto()))
                : ListView.builder(
                    itemCount: _followings.length,
                    itemBuilder: (context, index) {
                      final following = _followings[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: following.profilePic != null ? NetworkImage(following.profilePic!) : null,
                          child: following.profilePic == null ? Text(following.name[0].toUpperCase(), style: GoogleFonts.roboto()) : null,
                        ),
                        title: Text(following.name, style: GoogleFonts.roboto()),
                        // subtitle: Text(following.nickName, style: GoogleFonts.roboto()),
                        trailing: OutlinedButton(
                          style: ElevatedButton.styleFrom(minimumSize: Size(60, 40), side: BorderSide(
                              color: Color(0xFF7400A5),
                              width: 1.5,
                            ),
                          ),
                          onPressed: () => _startChat(following.id),
                          child: Text(
                            'Chat',
                            
                            style: GoogleFonts.roboto(fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class Following {
  final String id;
  final String name;
  final String nickName;
  final String? profilePic;
  final List<String> interests;

  Following({
    required this.id,
    required this.name,
    required this.nickName,
    this.profilePic,
    required this.interests,
  });

  factory Following.fromJson(Map<String, dynamic> json) {
    return Following(
      id: json['_id'],
      name: json['name'],
      nickName: json['nickName'],
      profilePic: json['profilePic'],
      interests: List<String>.from(json['interests'] ?? []),
    );
  }
}
