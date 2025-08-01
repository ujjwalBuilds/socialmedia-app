import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class ChatRoomSheetContent extends StatefulWidget {
  final Post post;

  const ChatRoomSheetContent({super.key, required this.post});

  @override
  State<ChatRoomSheetContent> createState() => ChatRoomSheetContentState();
}

class ChatRoomSheetContentState extends State<ChatRoomSheetContent> {
  late Future<List<ChatRoom>> _chatRoomsFuture;
  final Set<String> selectedChatRoomIds = {};
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _chatRoomsFuture = _fetchChatRooms();
  }

  Widget _buildChatRoomGrid(
    List<ChatRoom> chatRooms,
    Set<String> selectedChatRoomIds,
    String searchQuery,
    StateSetter setState,
    Post post,
  ) {
    // Filter chat rooms based on search query
    final filteredChatRooms = chatRooms.where((room) {
      final roomName = room.roomType == 'group' ? room.groupName?.toLowerCase() ?? '' : room.participants.first.name.toLowerCase();
      return roomName.contains(searchQuery);
    }).toList();

    if (filteredChatRooms.isEmpty) {
      return Center(
        child: Text(
          'No matching users found',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredChatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = filteredChatRooms[index];
        final isSelected = selectedChatRoomIds.contains(chatRoom.chatRoomId);

        final userName = chatRoom.roomType == 'group' ? chatRoom.groupName ?? 'Group' : chatRoom.participants.first.name;
        final profileImage = chatRoom.roomType == 'group' ? chatRoom.profileUrl : chatRoom.participants.first.profilePic;
        log(profileImage.toString());
        // final profileImage = chatRoom.roomType == 'group'
        //     ?
        //     : chatRoom.participants.first.profilePic != null
        //         ? SvgPicture.network(chatRoom.participants.first.profilePic!)
        //         : null;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedChatRoomIds.remove(chatRoom.chatRoomId);
              } else if (selectedChatRoomIds.length < 5) {
                selectedChatRoomIds.add(chatRoom.chatRoomId);
              } else {
                Fluttertoast.showToast(
                  msg: 'Maximum 5 recipients allowed',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            });
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 2) : null,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF7400A5),
                      child: profileImage != null
                          ? ClipOval(
                              child: Image.network(
                                profileImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/group.svg',
                              width: 25.w,
                              height: 25.w,
                            ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF7400A5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<ChatRoom>> _fetchChatRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('user_token');

    if (userId == null || token == null) {
      throw Exception('User ID or Token not found');
    }
    final response = await http.get(
      Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
      headers: {
        'userId': userId,
        'token': token,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Fetched Data: $data");

      List<ChatRoom> chatRooms = List<ChatRoom>.from(
        data['chatRooms'].map((x) {
          ChatRoom chatRoom = ChatRoom.fromJson(x);

          // Remove problematic chat room based on content type
          if (chatRoom.lastMessage?.content is Map<String, dynamic>) {
            print("Removed Chat Room ID: ${chatRoom.chatRoomId}");
            return null; // Skip this chat room
          }

          return chatRoom;
        }),
      ).whereType<ChatRoom>().toList(); // Removes null values

      print("Final Chat Rooms: $chatRooms");
      return chatRooms;
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }

  Future<void> _sendMessage(String chatRoomId, Post post) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getString('user_id');

    if (senderId != null) {
      final postJson = {
        '_id': post.id,
        'author': post.id,
        'data': {
          'content': post.content,
          'media': post.media,
        },
        'feedId': post.feedId,
        'name': post.usrname,
      };

      SocketService().sendMessage(senderId, chatRoomId, json.encode(postJson), '', false, false);

      Fluttertoast.showToast(
          msg: 'Sent',
          gravity: ToastGravity.CENTER,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7400A5),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No chat initiated',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${selectedChatRoomIds.length}/5 Selected',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF7400A5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white12,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Color(0xFF7400A5),
                      )),
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: _buildChatRoomGrid(
                    chatRooms,
                    selectedChatRoomIds,
                    searchQuery,
                    setState,
                    widget.post,
                  ),
                ),
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () async {
                        for (String chatRoomId in selectedChatRoomIds) {
                          await _sendMessage(chatRoomId, widget.post);
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF7400A5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Send to ${selectedChatRoomIds.length} ${selectedChatRoomIds.length == 1 ? 'recipient' : 'recipients'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class ChatRoomSheetContent extends StatefulWidget {
  final Post post;

  const ChatRoomSheetContent({super.key, required this.post});

  @override
  State<ChatRoomSheetContent> createState() => ChatRoomSheetContentState();
}

class ChatRoomSheetContentState extends State<ChatRoomSheetContent> {
  late Future<List<ChatRoom>> _chatRoomsFuture;
  final Set<String> selectedChatRoomIds = {};
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _chatRoomsFuture = _fetchChatRooms();
  }

  Widget _buildChatRoomGrid(
    List<ChatRoom> chatRooms,
    Set<String> selectedChatRoomIds,
    String searchQuery,
    StateSetter setState,
    Post post,
  ) {
    // Filter chat rooms based on search query
    final filteredChatRooms = chatRooms.where((room) {
      final roomName = room.roomType == 'group' ? room.groupName?.toLowerCase() ?? '' : room.participants.first.name.toLowerCase();
      return roomName.contains(searchQuery);
    }).toList();

    if (filteredChatRooms.isEmpty) {
      return Center(
        child: Text(
          'No matching users found',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredChatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = filteredChatRooms[index];
        final isSelected = selectedChatRoomIds.contains(chatRoom.chatRoomId);

        final userName = chatRoom.roomType == 'group' ? chatRoom.groupName ?? 'Group' : chatRoom.participants.first.name;
        final profileImage = chatRoom.roomType == 'group' ? chatRoom.profileUrl : chatRoom.participants.first.profilePic;
        log(profileImage.toString());
        // final profileImage = chatRoom.roomType == 'group'
        //     ?
        //     : chatRoom.participants.first.profilePic != null
        //         ? SvgPicture.network(chatRoom.participants.first.profilePic!)
        //         : null;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedChatRoomIds.remove(chatRoom.chatRoomId);
              } else if (selectedChatRoomIds.length < 5) {
                selectedChatRoomIds.add(chatRoom.chatRoomId);
              } else {
                Fluttertoast.showToast(
                  msg: 'Maximum 5 recipients allowed',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            });
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 2) : null,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF7400A5),
                      child: profileImage != null
                          ? ClipOval(
                              child: Image.network(
                                profileImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/group.svg',
                              width: 25.w,
                              height: 25.w,
                            ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF7400A5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<ChatRoom>> _fetchChatRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('user_token');

    if (userId == null || token == null) {
      throw Exception('User ID or Token not found');
    }
    final response = await http.get(
      Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
      headers: {
        'userId': userId,
        'token': token,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Fetched Data: $data");

      List<ChatRoom> chatRooms = List<ChatRoom>.from(
        data['chatRooms'].map((x) {
          ChatRoom chatRoom = ChatRoom.fromJson(x);

          // Remove problematic chat room based on content type
          if (chatRoom.lastMessage?.content is Map<String, dynamic>) {
            print("Removed Chat Room ID: ${chatRoom.chatRoomId}");
            return null; // Skip this chat room
          }

          return chatRoom;
        }),
      ).whereType<ChatRoom>().toList(); // Removes null values

      print("Final Chat Rooms: $chatRooms");
      return chatRooms;
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }

  Future<void> _sendMessage(String chatRoomId, Post post) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getString('user_id');

    if (senderId != null) {
      final postJson = {
        '_id': post.id,
        'author': post.id,
        'data': {
          'content': post.content,
          'media': post.media,
        },
        'feedId': post.feedId,
        'name': post.usrname,
      };

      SocketService().sendMessage(senderId, chatRoomId, json.encode(postJson), '', false, false);

      Fluttertoast.showToast(
          msg: 'Sent',
          gravity: ToastGravity.CENTER,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7400A5),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No chat initiated',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${selectedChatRoomIds.length}/5 Selected',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF7400A5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white12,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Color(0xFF7400A5),
                      )),
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: _buildChatRoomGrid(
                    chatRooms,
                    selectedChatRoomIds,
                    searchQuery,
                    setState,
                    widget.post,
                  ),
                ),
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () async {
                        for (String chatRoomId in selectedChatRoomIds) {
                          await _sendMessage(chatRoomId, widget.post);
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF7400A5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Send to ${selectedChatRoomIds.length} ${selectedChatRoomIds.length == 1 ? 'recipient' : 'recipients'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class ChatRoomSheetContent extends StatefulWidget {
  final Post post;

  const ChatRoomSheetContent({super.key, required this.post});

  @override
  State<ChatRoomSheetContent> createState() => ChatRoomSheetContentState();
}

class ChatRoomSheetContentState extends State<ChatRoomSheetContent> {
  late Future<List<ChatRoom>> _chatRoomsFuture;
  final Set<String> selectedChatRoomIds = {};
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _chatRoomsFuture = _fetchChatRooms();
  }

  Widget _buildChatRoomGrid(
    List<ChatRoom> chatRooms,
    Set<String> selectedChatRoomIds,
    String searchQuery,
    StateSetter setState,
    Post post,
  ) {
    // Filter chat rooms based on search query
    final filteredChatRooms = chatRooms.where((room) {
      final roomName = room.roomType == 'group' ? room.groupName?.toLowerCase() ?? '' : room.participants.first.name.toLowerCase();
      return roomName.contains(searchQuery);
    }).toList();

    if (filteredChatRooms.isEmpty) {
      return Center(
        child: Text(
          'No matching users found',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredChatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = filteredChatRooms[index];
        final isSelected = selectedChatRoomIds.contains(chatRoom.chatRoomId);

        final userName = chatRoom.roomType == 'group' ? chatRoom.groupName ?? 'Group' : chatRoom.participants.first.name;
        final profileImage = chatRoom.roomType == 'group' ? chatRoom.profileUrl : chatRoom.participants.first.profilePic;
        log(profileImage.toString());
        // final profileImage = chatRoom.roomType == 'group'
        //     ?
        //     : chatRoom.participants.first.profilePic != null
        //         ? SvgPicture.network(chatRoom.participants.first.profilePic!)
        //         : null;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedChatRoomIds.remove(chatRoom.chatRoomId);
              } else if (selectedChatRoomIds.length < 5) {
                selectedChatRoomIds.add(chatRoom.chatRoomId);
              } else {
                Fluttertoast.showToast(
                  msg: 'Maximum 5 recipients allowed',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            });
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 2) : null,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF7400A5),
                      child: profileImage != null
                          ? ClipOval(
                              child: Image.network(
                                profileImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/group.svg',
                              width: 25.w,
                              height: 25.w,
                            ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF7400A5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<ChatRoom>> _fetchChatRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('user_token');

    if (userId == null || token == null) {
      throw Exception('User ID or Token not found');
    }
    final response = await http.get(
      Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
      headers: {
        'userId': userId,
        'token': token,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Fetched Data: $data");

      List<ChatRoom> chatRooms = List<ChatRoom>.from(
        data['chatRooms'].map((x) {
          ChatRoom chatRoom = ChatRoom.fromJson(x);

          // Remove problematic chat room based on content type
          if (chatRoom.lastMessage?.content is Map<String, dynamic>) {
            print("Removed Chat Room ID: ${chatRoom.chatRoomId}");
            return null; // Skip this chat room
          }

          return chatRoom;
        }),
      ).whereType<ChatRoom>().toList(); // Removes null values

      print("Final Chat Rooms: $chatRooms");
      return chatRooms;
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }

  Future<void> _sendMessage(String chatRoomId, Post post) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getString('user_id');

    if (senderId != null) {
      final postJson = {
        '_id': post.id,
        'author': post.id,
        'data': {
          'content': post.content,
          'media': post.media,
        },
        'feedId': post.feedId,
        'name': post.usrname,
      };

      SocketService().sendMessage(senderId, chatRoomId, json.encode(postJson), '', false, false);

      Fluttertoast.showToast(
          msg: 'Sent',
          gravity: ToastGravity.CENTER,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7400A5),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No chat initiated',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${selectedChatRoomIds.length}/5 Selected',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF7400A5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white12,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Color(0xFF7400A5),
                      )),
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: _buildChatRoomGrid(
                    chatRooms,
                    selectedChatRoomIds,
                    searchQuery,
                    setState,
                    widget.post,
                  ),
                ),
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () async {
                        for (String chatRoomId in selectedChatRoomIds) {
                          await _sendMessage(chatRoomId, widget.post);
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF7400A5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Send to ${selectedChatRoomIds.length} ${selectedChatRoomIds.length == 1 ? 'recipient' : 'recipients'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class ChatRoomSheetContent extends StatefulWidget {
  final Post post;

  const ChatRoomSheetContent({super.key, required this.post});

  @override
  State<ChatRoomSheetContent> createState() => ChatRoomSheetContentState();
}

class ChatRoomSheetContentState extends State<ChatRoomSheetContent> {
  late Future<List<ChatRoom>> _chatRoomsFuture;
  final Set<String> selectedChatRoomIds = {};
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _chatRoomsFuture = _fetchChatRooms();
  }

  Widget _buildChatRoomGrid(
    List<ChatRoom> chatRooms,
    Set<String> selectedChatRoomIds,
    String searchQuery,
    StateSetter setState,
    Post post,
  ) {
    // Filter chat rooms based on search query
    final filteredChatRooms = chatRooms.where((room) {
      final roomName = room.roomType == 'group' ? room.groupName?.toLowerCase() ?? '' : room.participants.first.name.toLowerCase();
      return roomName.contains(searchQuery);
    }).toList();

    if (filteredChatRooms.isEmpty) {
      return Center(
        child: Text(
          'No matching users found',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredChatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = filteredChatRooms[index];
        final isSelected = selectedChatRoomIds.contains(chatRoom.chatRoomId);

        final userName = chatRoom.roomType == 'group' ? chatRoom.groupName ?? 'Group' : chatRoom.participants.first.name;
        final profileImage = chatRoom.roomType == 'group' ? chatRoom.profileUrl : chatRoom.participants.first.profilePic;
        log(profileImage.toString());
        // final profileImage = chatRoom.roomType == 'group'
        //     ?
        //     : chatRoom.participants.first.profilePic != null
        //         ? SvgPicture.network(chatRoom.participants.first.profilePic!)
        //         : null;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedChatRoomIds.remove(chatRoom.chatRoomId);
              } else if (selectedChatRoomIds.length < 5) {
                selectedChatRoomIds.add(chatRoom.chatRoomId);
              } else {
                Fluttertoast.showToast(
                  msg: 'Maximum 5 recipients allowed',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            });
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 2) : null,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF7400A5),
                      child: profileImage != null
                          ? ClipOval(
                              child: Image.network(
                                profileImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/group.svg',
                              width: 25.w,
                              height: 25.w,
                            ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF7400A5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<ChatRoom>> _fetchChatRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('user_token');

    if (userId == null || token == null) {
      throw Exception('User ID or Token not found');
    }
    final response = await http.get(
      Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
      headers: {
        'userId': userId,
        'token': token,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Fetched Data: $data");

      List<ChatRoom> chatRooms = List<ChatRoom>.from(
        data['chatRooms'].map((x) {
          ChatRoom chatRoom = ChatRoom.fromJson(x);

          // Remove problematic chat room based on content type
          if (chatRoom.lastMessage?.content is Map<String, dynamic>) {
            print("Removed Chat Room ID: ${chatRoom.chatRoomId}");
            return null; // Skip this chat room
          }

          return chatRoom;
        }),
      ).whereType<ChatRoom>().toList(); // Removes null values

      print("Final Chat Rooms: $chatRooms");
      return chatRooms;
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }

  Future<void> _sendMessage(String chatRoomId, Post post) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getString('user_id');

    if (senderId != null) {
      final postJson = {
        '_id': post.id,
        'author': post.id,
        'data': {
          'content': post.content,
          'media': post.media,
        },
        'feedId': post.feedId,
        'name': post.usrname,
      };

      SocketService().sendMessage(senderId, chatRoomId, json.encode(postJson), '', false, false);

      Fluttertoast.showToast(
          msg: 'Sent',
          gravity: ToastGravity.CENTER,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7400A5),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No chat initiated',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${selectedChatRoomIds.length}/5 Selected',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF7400A5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white12,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Color(0xFF7400A5),
                      )),
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: _buildChatRoomGrid(
                    chatRooms,
                    selectedChatRoomIds,
                    searchQuery,
                    setState,
                    widget.post,
                  ),
                ),
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () async {
                        for (String chatRoomId in selectedChatRoomIds) {
                          await _sendMessage(chatRoomId, widget.post);
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF7400A5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Send to ${selectedChatRoomIds.length} ${selectedChatRoomIds.length == 1 ? 'recipient' : 'recipients'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class ChatRoomSheetContent extends StatefulWidget {
  final Post post;

  const ChatRoomSheetContent({super.key, required this.post});

  @override
  State<ChatRoomSheetContent> createState() => ChatRoomSheetContentState();
}

class ChatRoomSheetContentState extends State<ChatRoomSheetContent> {
  late Future<List<ChatRoom>> _chatRoomsFuture;
  final Set<String> selectedChatRoomIds = {};
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _chatRoomsFuture = _fetchChatRooms();
  }

  Widget _buildChatRoomGrid(
    List<ChatRoom> chatRooms,
    Set<String> selectedChatRoomIds,
    String searchQuery,
    StateSetter setState,
    Post post,
  ) {
    // Filter chat rooms based on search query
    final filteredChatRooms = chatRooms.where((room) {
      final roomName = room.roomType == 'group' ? room.groupName?.toLowerCase() ?? '' : room.participants.first.name.toLowerCase();
      return roomName.contains(searchQuery);
    }).toList();

    if (filteredChatRooms.isEmpty) {
      return Center(
        child: Text(
          'No matching users found',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredChatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = filteredChatRooms[index];
        final isSelected = selectedChatRoomIds.contains(chatRoom.chatRoomId);

        final userName = chatRoom.roomType == 'group' ? chatRoom.groupName ?? 'Group' : chatRoom.participants.first.name;
        final profileImage = chatRoom.roomType == 'group' ? chatRoom.profileUrl : chatRoom.participants.first.profilePic;
        log(profileImage.toString());
        // final profileImage = chatRoom.roomType == 'group'
        //     ?
        //     : chatRoom.participants.first.profilePic != null
        //         ? SvgPicture.network(chatRoom.participants.first.profilePic!)
        //         : null;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedChatRoomIds.remove(chatRoom.chatRoomId);
              } else if (selectedChatRoomIds.length < 5) {
                selectedChatRoomIds.add(chatRoom.chatRoomId);
              } else {
                Fluttertoast.showToast(
                  msg: 'Maximum 5 recipients allowed',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            });
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Color(0xFF7400A5), width: 2) : null,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF7400A5),
                      child: profileImage != null
                          ? ClipOval(
                              child: Image.network(
                                profileImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/group.svg',
                              width: 25.w,
                              height: 25.w,
                            ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF7400A5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<ChatRoom>> _fetchChatRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('user_token');

    if (userId == null || token == null) {
      throw Exception('User ID or Token not found');
    }
    final response = await http.get(
      Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
      headers: {
        'userId': userId,
        'token': token,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Fetched Data: $data");

      List<ChatRoom> chatRooms = List<ChatRoom>.from(
        data['chatRooms'].map((x) {
          ChatRoom chatRoom = ChatRoom.fromJson(x);

          // Remove problematic chat room based on content type
          if (chatRoom.lastMessage?.content is Map<String, dynamic>) {
            print("Removed Chat Room ID: ${chatRoom.chatRoomId}");
            return null; // Skip this chat room
          }

          return chatRoom;
        }),
      ).whereType<ChatRoom>().toList(); // Removes null values

      print("Final Chat Rooms: $chatRooms");
      return chatRooms;
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }

  Future<void> _sendMessage(String chatRoomId, Post post) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getString('user_id');

    if (senderId != null) {
      final postJson = {
        '_id': post.id,
        'author': post.id,
        'data': {
          'content': post.content,
          'media': post.media,
        },
        'feedId': post.feedId,
        'name': post.usrname,
      };

      SocketService().sendMessage(senderId, chatRoomId, json.encode(postJson), '', false, false);

      Fluttertoast.showToast(
          msg: 'Sent',
          gravity: ToastGravity.CENTER,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7400A5),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No chat initiated',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${selectedChatRoomIds.length}/5 Selected',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF7400A5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white12,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Color(0xFF7400A5),
                      )),
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: _buildChatRoomGrid(
                    chatRooms,
                    selectedChatRoomIds,
                    searchQuery,
                    setState,
                    widget.post,
                  ),
                ),
                if (selectedChatRoomIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () async {
                        for (String chatRoomId in selectedChatRoomIds) {
                          await _sendMessage(chatRoomId, widget.post);
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF7400A5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Send to ${selectedChatRoomIds.length} ${selectedChatRoomIds.length == 1 ? 'recipient' : 'recipients'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
