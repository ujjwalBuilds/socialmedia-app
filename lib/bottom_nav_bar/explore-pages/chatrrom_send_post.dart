import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chat_room_sheet.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';

class ChatRoom {
  final String id;
  final String chatRoomId;
  final List<Participant> participants;
  final String roomType;
  final String? groupName;
  final String? profileUrl;
  final String? admin;
  final LastMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.chatRoomId,
    required this.participants,
    required this.roomType,
    this.groupName,
    this.profileUrl,
    this.admin,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'],
      chatRoomId: json['chatRoomId'],
      participants: List<Participant>.from(
        json['participants'].map((x) => Participant.fromJson(x)),
      ),
      roomType: json['roomType'],
      groupName: json['groupName'],
      profileUrl: json['profileUrl'],
      admin: json['admin'],
      lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null,
    );
  }
}

class Participant {
  final String userId;
  final String? profilePic;
  final String name;

  Participant({
    required this.userId,
    this.profilePic,
    required this.name,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'],
      profilePic: json['profilePic'],
      name: json['name'],
    );
  }
}

class LastMessage {
  final String messageId;
  final int timestamp;
  final dynamic content;

  LastMessage({
    required this.messageId,
    required this.timestamp,
    required this.content,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      messageId: json['messageId'],
      timestamp: json['timestamp'],
      content: json['content'] is String ? json['content'] : jsonEncode(json['content']),
    );
  }
}

void showChatRoomSheet(BuildContext context, Post post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: MediaQuery.of(context).viewInsets.bottom > 0 ? MediaQuery.of(context).size.height * 0.9 : MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ChatRoomSheetContent(post: post),
        ),
      );
    },
  );
}
