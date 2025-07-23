import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/services/agora_Call_Service.dart';
import 'package:socialmedia/services/agora_video_Call.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:provider/provider.dart';

class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  final SocketService _socketService = SocketService();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;
  Timer? _connectionCheckTimer;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _ensureConnection();
   // _setupCallHandlers();
    _startConnectionCheck();
    _isInitialized = true;
  }

  Future<void> _ensureConnection() async {
    if (!_socketService.isConnected) {
      await _socketService.connect();
    }
  }

  void _startConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_socketService.isConnected) {
        print('Socket disconnected, attempting to reconnect...');
        await _socketService.connect();
      }
    });
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
  }

 /* void _setupCallHandlers() {
    // Handle incoming calls
    _socketService.socket.on('pickUp', (data) async {
      print('Incoming call data: $data');

      final BuildContext? currentContext = navigatorKey.currentContext;
      if (currentContext == null) {
        print('Error: No valid context found');
        return;
      }

      // Get user details from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print('Error: User ID not found');
        return;
      }

      // Join the call room
      _socketService.socket.emit('joinCall', {
        'callId': data['callId'],
        'userId': userId
      });

      _showIncomingCallModal(currentContext, data);
    });

    // Handle call ended
    _socketService.socket.on('callEnded', (data) {
      print('Call ended: $data');
      final BuildContext? currentContext = navigatorKey.currentContext;
      if (currentContext != null) {
        Navigator.of(currentContext).popUntil((route) => route.isFirst);
      }
    });

    // Handle user joined
    _socketService.socket.on('userJoined', (data) {
      print('User joined call: $data');
    });

    // Handle user left
    _socketService.socket.on('userLeft', (data) {
      print('User left call: $data');
    });
  }*/

 /* void _showIncomingCallModal(BuildContext context, dynamic data) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalContext) {
      return WillPopScope(
        onWillPop: () async => false, // Prevent dismissing with back button
        child: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.30,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Profile picture, name and calling text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: data['senderInfo']['profilePic'] != null
                            ? NetworkImage(data['senderInfo']['profilePic'])
                            : NetworkImage(data['senderInfo']['avatar']),
                        child: data['senderInfo']['profilePic'] == null
                            ? data['senderInfo']['avatar'] == null ?
                            const Icon(Icons.person, size: 30, color: Colors.white)
                            : null :null,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${data['senderInfo']['name'] ?? 'Unknown'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${data['type']} Calling...",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Call action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reject button (red)
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      child: ElevatedButton(
                        onPressed: () {
                          _rejectCall(modalContext, data['callId']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                    
                    // Accept button (green)
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      child: ElevatedButton(
                        onPressed: () {
                          _acceptCall(modalContext, data['callId'], data['type'] , data['senderInfo']['name'] ?? 'Unknown' , data['senderInfo']['avatar'] ?? '');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bottom bar indicator
                
              ],
            ),
          ),
        ),
      );
    },
  );
}*/



  Future<void> _acceptCall(BuildContext context, String callId, String type , String name , String profilepic ) async {
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        print('Error: Missing user credentials');
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/accept-call'),
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'callId': callId
        }),
      );

      print('Accept call response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final agoraToken = data['token'];
        final channelName = data['channelName'];

        if (agoraToken == null || channelName == null) {
          print('Error: Missing token or channelName');
          return;
        }

        // Close the incoming call modal
        Navigator.pop(context);

        // Navigate to appropriate call screen
        if (type == 'video') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgoraVidCall(
                channel: channelName,
                token: agoraToken,
                callerName: 'Video Call',
                call_id: callId,
                name: name,
                profile: profilepic
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgoraCallService(
                channel: channelName,
                token: agoraToken,
                callID: callId,
                profile: profilepic,
                name: name               
              ),
            ),
          );
        }
      } else {
        print('Failed to accept call: ${response.body}');
        Fluttertoast.showToast(msg: 'Failed' , gravity: ToastGravity.BOTTOM , toastLength: Toast.LENGTH_SHORT);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> BottomNavBarScreen()));
      }
    } catch (e) {
      print('Error accepting call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Error: $e'))),
      );
    }
  }

  Future<void> _rejectCall(BuildContext context, String callId) async {
    final String url = '${BASE_URL}api/update-call-status';
     try {
      // Get userId and token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? token = prefs.getString('user_token');

      if (userId == null || token == null) {
        throw Exception("User ID or token not found in SharedPreferences");
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'token': token,
        'userId': userId,
      };

      Map<String, dynamic> body = {
        'callId': callId,
        'status': 'ended',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("Call status updated successfully: ${response.body}");
        Navigator.push(context, MaterialPageRoute(builder: (context)=> BottomNavBarScreen()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context)=> BottomNavBarScreen()));
        print(
            "Failed to update call status: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error updating call status: $e");
    }
  }
}

class ChatRoom {
  final String chatRoomId;
  final List<Participant> participants;
  final String? groupName;
  final String roomType;

  ChatRoom({
    required this.chatRoomId,
    required this.participants,
    this.groupName,
    required this.roomType,
  });

  // ... rest of your ChatRoom implementation
}

class Participant {
  final String userId;
  final String? name;
  final String? profilePic;

  Participant({
    required this.userId,
    this.name,
    this.profilePic,
  });

  // ... rest of your Participant implementation
}