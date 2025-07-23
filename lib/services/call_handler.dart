import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/agora_Call_Service.dart';
import 'package:socialmedia/services/agora_video_Call.dart';
import 'package:http/http.dart' as http;

class CallHandler {
  static final CallHandler _instance = CallHandler._internal();
  final Uuid _uuid = Uuid();
  
  factory CallHandler() {
    return _instance;
  }
  
  CallHandler._internal();
  
  // Process incoming call notification
  Future<void> processCallNotification(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      // Parse the data payload from FCM notification
      final Map<String, dynamic> payload = jsonDecode(data['data']);
      
      // Extract call information
      final callType = payload['callType'];
      final callId = payload['callId'];
      final senderId = payload['senderId'];
      final senderInfo = payload['senderInfo'];
      
      // Skip if the call is from the current user
      if (senderId == userId) {
        print('Ignoring call notification from self');
        return;
      }
      
      // Extract caller information
      final callerName = senderInfo['name'] ?? 'Unknown';
      final callerProfilePic = senderInfo['profilePic'] ?? '';
      
      // Show the incoming call UI
      await showCallkitIncoming(callId, callType, callerName, callerProfilePic);
    } catch (e) {
      print('Error processing call notification: $e');
    }
  }
  
  // Show incoming call UI using flutter_callkit_incoming
  Future<void> showCallkitIncoming(String callId, String callType, String callerName, String profilePic) async {
    print('📞 Setting up incoming call UI');
    print('   - Call ID: $callId');
    print('   - Type: $callType');
    print('   - Caller: $callerName');
    
    // Create CallKitParams based on the provided example
    CallKitParams callKitParams = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Your App Name',
      avatar: profilePic.isNotEmpty ? profilePic : 'https://i.pravatar.cc/100',
      handle: callType == 'video' ? 'Video Call' : 'Audio Call',
      type: callType == 'video' ? 1 : 0, // 0 for audio call, 1 for video call
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call from $callerName',
        callbackText: 'Call back',
      ),
      callingNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Incoming ${callType == "video" ? "video" : "audio"} call...',
        callbackText: 'Hang Up',
      ),
      duration: 30000, // 30 seconds ring duration
      extra: <String, dynamic>{
        'callId': callId,
        'callType': callType,
        'callerName': callerName,
        'profilePic': profilePic,
      },
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: profilePic.isNotEmpty ? profilePic : null,
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: "Incoming Call",
        missedCallNotificationChannelName: "Missed Call",
        isShowCallID: false
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: callType == 'video' ? 'video' : 'generic',
        supportsVideo: callType == 'video',
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    
    print('📱 Showing CallKit UI...');
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
      print('✅ CallKit UI shown successfully');
    } catch (e) {
      print('❌ Error showing CallKit UI: $e');
    }
  }
  
  // Initialize call listener (to be called during app startup)
  void initCallListener() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      print('CallKit event received: ${event?.event}');
      print('CallKit event received: ${event?.body}');
      
      // Use the correct string constants for the event names
      switch (event?.event) {
        case Event.actionCallAccept:
          print('Call accepted: ${event?.body}');
          final callId = event?.body['id'] ?? '';
          final extra = event?.body['extra'] ?? {};
          final callType = extra['callType'] ?? 'audio';
          final callerName = extra['callerName'] ?? 'Unknown';
          final profilePic = extra['profilePic'] ?? '';
          
          // Handle call acceptance
          await handleAcceptCall(callId, callType, callerName, profilePic);
          break;
          
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE':
          print('Call declined: ${event?.body}');
          final callId = event?.body['id'] ?? '';
          await handleRejectCall(callId);
          break;
          
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TIMEOUT':
          print('Call timeout: ${event?.body}');
          final callId = event?.body['id'] ?? '';
          await handleRejectCall(callId);
          break;
          
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_CALLBACK':
          print('Call callback: ${event?.body}');
          // Handle callback if needed
          break;
          
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_HOLD':
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_MUTE':
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_DMTF':
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_GROUP':
        case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_AUDIO_SESSION':
          // Handle other call actions if needed
          print('Other call action: ${event?.event}');
          break;
          
        default:
          print('Unknown call event: ${event?.event}');
          break;
      }
    });
  }
  
  // Handle accepted call
  Future<void> handleAcceptCall(String callId, String type, String name, String profilePic) async {
    print('📞 Starting handleAcceptCall');
    print('   - Call ID: $callId');
    print('   - Type: $type');
    print('   - Name: $name');
    
    try {
      // First, check if there are any active calls
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      print('📱 Active calls: ${activeCalls.length}');
      
      // Only check for active calls if we're not already in a call
      if (activeCalls.isNotEmpty && !activeCalls.any((call) => call['id'] == callId)) {
        print('⚠️ Another call is in progress, ignoring new call');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        print('❌ Error: Missing user credentials');
        return;
      }

      print('🔑 User credentials found');
      print('   - User ID: $userId');
      print('   - Token: ${token.substring(0, 10)}...');

      // First, show a loading indicator or prepare the UI
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Center(child: Text('Connecting call...')),
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('📡 Sending accept-call request...');
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

      print('📥 Accept call response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final agoraToken = data['token'];
        final channelName = data['channelName'];

        if (agoraToken == null || channelName == null) {
          print('❌ Error: Missing token or channelName');
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(content: Center(child: Text('Error: Missing call credentials'))),
            );
          }
          return;
        }

        print('✅ Got Agora credentials');
        print('   - Channel: $channelName');
        print('   - Token: ${agoraToken.substring(0, 10)}...');

        // Ensure we have a valid context before navigation
        if (navigatorKey.currentContext != null) {
          print('🚀 Starting navigation to call screen...');
          // Use a small delay to ensure UI is ready
          await Future.delayed(Duration(milliseconds: 500));
          
          // Navigate to appropriate call screen based on call type
          if (type == 'video') {
            print('📹 Navigating to video call screen');
            await Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (context) => AgoraVidCall(
                  channel: channelName,
                  token: agoraToken,
                  callerName: 'Video Call',
                  call_id: callId,
                  name: name,
                  profile: profilePic
                ),
              ),
            );
          } else {
            print('🎤 Navigating to audio call screen');
            await Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (context) => AgoraCallService(
                  channel: channelName,
                  token: agoraToken,
                  callID: callId,
                  profile: profilePic,
                  name: name               
                ),
              ),
            );
          }
          print('✅ Navigation complete');
        } else {
          print('❌ No valid context available for navigation');
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(content: Center(child: Text('Error: Unable to start call'))),
            );
          }
        }
      } else {
        print('❌ Failed to accept call: ${response.body}');
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Center(child: Text('Failed to connect call')),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error accepting call: $e');
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Center(child: Text('Error: Failed to connect call')),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  // Handle rejected call
  Future<void> handleRejectCall(String callId) async {
    final String url = '${BASE_URL}api/update-call-status';
    
    try {
      // Get userId and token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? token = prefs.getString('user_token');

      if (userId == null || token == null) {
        throw Exception("User ID or token not found in SharedPreferences");
      }

      // First, end the call in CallKit
      await FlutterCallkitIncoming.endCall(callId);

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
        // Ensure we have a valid context before navigation
        if (navigatorKey.currentContext != null) {
          // Pop back to the previous screen
          Navigator.pop(navigatorKey.currentContext!);
        }
      } else {
        print("Failed to update call status: ${response.statusCode} - ${response.body}");
        if (navigatorKey.currentContext != null) {
          // Show error message
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Center(child: Text('Failed to end call')),
              duration: Duration(seconds: 2),
            ),
          );
          // Pop back to the previous screen
          Navigator.pop(navigatorKey.currentContext!);
        }
      }
    } catch (e) {
      print("Error updating call status: $e");
      if (navigatorKey.currentContext != null) {
        // Show error message
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Center(child: Text('Error ending call')),
            duration: Duration(seconds: 2),
          ),
        );
        // Pop back to the previous screen
        Navigator.pop(navigatorKey.currentContext!);
      }
    }
  }

  // Add a method to properly end all active calls
  Future<void> endAllCalls() async {
    try {
      // Get all active calls
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      
      // End each active call
      for (final call in activeCalls) {
        await FlutterCallkitIncoming.endCall(call['id']);
      }
    } catch (e) {
      print('Error ending all calls: $e');
    }
  }
}