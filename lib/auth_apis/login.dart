import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/pages/onboarding_screens/blannk.dart';
import 'package:socialmedia/services/agora_Call_Service.dart';
import 'package:socialmedia/services/agora_video_Call.dart';
import 'package:socialmedia/services/call_handler.dart';
import 'package:socialmedia/services/call_manager.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/services/provider/notification_provider.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/utils/constants.dart';

Future<void> loginUser(BuildContext context, phoneNumber, String countryCode,
    String password) async {
  final String apiUrl = "${BASE_URL}api/login";

  // Construct the request body
  final Map<String, dynamic> requestBody = {
    "phoneNumber": phoneNumber,
    "countryCode": countryCode,
    "password": password
  };

  try {
    // Send the POST request
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final userProviderAll =
          Provider.of<UserProviderall>(context, listen: false);

      // Parse and handle the response
      final data = jsonDecode(response.body);
      print("Login Successful: $data");
      await userProviderAll.saveUserData(data);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String usr_token = data['token'];
      await prefs.setString('user_token', usr_token);
      final String usr_id = data['userDetails']['_id'];
      await prefs.setString('user_id', usr_id);
      final String socket_Token = data['socketToken'];
      await prefs.setString('socketToken', socket_Token);
      final String userName = data['userDetails']['name'];
      final String deviceId = data['deviceId'];

      await prefs.setString('deviceId', deviceId);

      await prefs.setString(
          'user_temp_profilepic', data['userDetails']['profilePic']);
      //  await prefs.setString('user_name', userName);

      await prefs.setString('loginstatus', '3');
      await prefs.commit();

      //CallManager().initializeServices();
      final socketService = SocketService();
      await socketService.connect();

      // Then initialize call manager
      final callManager = CallManager();
      await callManager.initialize();

      // Store the login timestamp
      await prefs.setInt(
          'last_login_time', DateTime.now().millisecondsSinceEpoch);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBarScreen()),
        (route) => false, // Remove all previous routes
      );
      updateFCMToken(usr_id, usr_token, context);
      initializeFCMListener(usr_id);
    } else {
      // Handle error responses
      final errorData = jsonDecode(response.body);
      final errorMessage =
          errorData['message'] ?? 'Invalid credentials. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              errorMessage,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          // action: SnackBarAction(
          //   label: 'Dismiss',
          //   textColor: Colors.white,
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
          //   },
          // ),
        ),
      );

      print("Failed to login. Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
    }
  } catch (e) {
    // Handle network or other errors with SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
            child: Text(
                'Connection error. Please check your internet connection.', style: TextStyle(color: Colors.white),)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    print("Error occurred during login: $e");
  }
}

Future<void> updateFCMToken(
    String userid, String token, BuildContext context) async {
  final url = Uri.parse('${BASE_URL}api/edit-profile');

  print('edit porifile callhhua');
  try {
    // Get the FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $fcmToken");

    if (fcmToken == null) {
      print('FCM token is null. Cannot proceed.');
      return;
    }

    // Create a MultipartRequest
    final request = http.MultipartRequest('PUT', url)
      ..headers.addAll({
        'userId': userid,
        'token': token,
      });

    // Add only fcmToken to the request
    request.fields['fcmToken'] = fcmToken;

    // Send the request
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print('FCM token updated successfully.');
      print('Response: $responseBody');
    } else {
      final responseBody = await response.stream.bytesToString();
      print('Failed to update FCM token. Status Code: ${response.statusCode}');
      print('Error: $responseBody');
    }
  } catch (e) {
    print('An error occurred while updating FCM token: $e');
  }
}

void initializeFCMListener(String? user_id) {
  // Initialize the call handler
  final callHandler = CallHandler();

  // Initialize the call listener (no context needed)
  callHandler.initCallListener();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

    Provider.of<NotificationProvider>(navigatorKey.currentContext!, listen: false).showNotification();


    print("🔔 New Notification Received");

    // Print the full message payload
    print("🔹 Full Message: ${message.toMap()}");

    // Print notification part (if sent via notification block)
    print("🔸 Title: ${message.notification?.title}");
    print("🔸 Body: ${message.notification?.body}");

    // Print custom data payload
    print("📦 Data: ${message.data}");

    // Check if this is a call notification
    final title = message.notification?.title ?? '';
    final isIncomingCall = title.contains('Incoming') && title.contains('Call');

    final rawData = message.data['data'];
    final dataPayload = rawData is String ? jsonDecode(rawData) : rawData;

    log('Data Payload: $dataPayload');

    // ✅ Step 2: Compare sender ID
    final senderId = dataPayload['senderId'];

    // Add check to prevent receiving notifications for your own calls
    if (isIncomingCall && message.data['data'] != null && senderId != user_id) {
      try {
        // Parse the data payload
        final dataPayload = jsonDecode(message.data['data']);
        final callId = dataPayload['callId'];
        final callType = dataPayload['callType'];
        final senderInfo = dataPayload['senderInfo'];

        // Show call UI
        await callHandler.showCallkitIncoming(
          callId,
          callType,
          senderInfo['name'] ?? 'Unknown',
          senderInfo['profilePic'] ?? '',
        );
      } catch (e) {
        print('Error handling call notification: $e');
      }
    } else if (senderId == user_id) {
      print('Ignoring notification from self');
      return;
    } else {
      // Process regular notification
      // Check if this is a call notification before showing badge
      final notificationType = dataPayload['type'];
      if (notificationType == 'call') {
        print('Ignoring call notification badge');
        return;
      }

      var androidDetails = const AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notificationn',
        enableVibration: true,
        enableLights: true,
        playSound: true,
        number: 1,
      );

      var iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      var generalDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Increment badge count
      final prefs = await SharedPreferences.getInstance();
      int currentBadgeCount = prefs.getInt('badge_count') ?? 0;
      currentBadgeCount++;
      await prefs.setInt('badge_count', currentBadgeCount);

      await localNotifications.show(
        currentBadgeCount,
        message.notification?.title ?? 'No Title',
        message.notification?.body ?? 'No Body',
        generalDetails,
      );
    }
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print("Notification clicked: ${message.notification?.title}");
      // Handle the notification when app is opened from terminated state
      _showRegularNotification(message);
      _handleNotificationTap(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("User clicked notification: ${message.notification?.title}");
    // Handle the notification when app is opened from background
    _showRegularNotification(message);
    _handleNotificationTap(message);
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// Separate function for regular notifications
void _showRegularNotification(RemoteMessage message) async {
  var androidDetails = const AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_notificationn',
    enableVibration: true,
    enableLights: true,
    playSound: true,
    channelShowBadge: true,
    number: 1,
  );

  var iosDetails = const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    badgeNumber: 1,
  );

  var generalDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  // Increment badge count
  final prefs = await SharedPreferences.getInstance();
  int currentBadgeCount = prefs.getInt('badge_count') ?? 0;
  currentBadgeCount++;
  await prefs.setInt('badge_count', currentBadgeCount);

  // await localNotifications.show(
  //   currentBadgeCount,
  //   message.notification?.title ?? 'No Title',
  //   message.notification?.body ?? 'No Body',
  //   generalDetails,
  // );
}

void _handleNotificationTap(RemoteMessage message) {
  if (message.data['data'] != null) {
    final dynamic rawData = message.data['data'];

    // Decode nested stringified JSON
    final decoded = rawData is String ? jsonDecode(rawData) : rawData;

    final type = decoded['type'];
    print('🔄 Notification Type: $type');

    if (type == 'reaction') {
      navigatorKey.currentState?.pushNamed('/notifications');
    } else if (type == 'message') {
      navigatorKey.currentState?.pushNamed('/activity');
    }
  }
}
