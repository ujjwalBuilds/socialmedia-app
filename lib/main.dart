import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/auth_apis/login.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/chatProvider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/communityProvider.dart';
import 'package:socialmedia/firebase_options.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection.dart';
import 'package:socialmedia/pages/onboarding_screens/interests.dart';
import 'package:socialmedia/pages/onboarding_screens/login_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/otp_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/signup_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/start_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/user_input_fields.dart';
import 'package:socialmedia/services/call_manager.dart';
import 'package:socialmedia/services/call_handler.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/services/provider/notification_provider.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/notification.dart';
import 'package:socialmedia/utils/colors.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.notification?.title}");
  print('Message data: ${message.data}');

  // Check if this is a call notification
  if (message.data['type'] == 'call') {
    final callHandler = CallHandler();
    try {
      await callHandler.showCallkitIncoming(
        message.data['callId'] ?? '',
        message.data['callType'] ?? 'audio',
        message.data['callerName'] ?? 'Unknown',
        message.data['profilePic'] ?? '',
      );
    } catch (e) {
      print('Error handling background call: $e');
    }
    return;
  }

  // Handle regular notification
  var androidSettings = const AndroidInitializationSettings('ic_notificationn');
  var iosSettings = const DarwinInitializationSettings();
  var initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      if (response.payload != null) {
        await _handleNotificationPayload(response.payload!);
      }
    },
  );

  // Get current badge count and increment
  final prefs = await SharedPreferences.getInstance();
  int currentBadgeCount = prefs.getInt('badge_count') ?? 0;
  currentBadgeCount++;
  await prefs.setInt('badge_count', currentBadgeCount);

  // Show notification
  await localNotifications.show(
    currentBadgeCount,
    message.notification?.title ?? 'No Title',
    message.notification?.body ?? 'No Body',
    NotificationDetails(
      android: const AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notificationn',
        channelShowBadge: true,
      ),
      iOS: DarwinNotificationDetails(
        badgeNumber: currentBadgeCount,
      ),
    ),
    payload: jsonEncode({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data['data'] ?? jsonEncode(message.data),
    }),
  );
}

Future<void> _handleNotificationPayload(String payload) async {
  try {
    print('Handling notification payload: $payload');
    final decoded = jsonDecode(payload);

    // Handle nested JSON in data field
    final dynamic data = decoded['data'];
    final Map<String, dynamic> notificationData = data is String ? jsonDecode(data) : data;

    final type = notificationData['type']?.toString() ?? '';
    print('Notification type: $type');

    if (navigatorKey.currentState == null) {
      print('Navigator not ready, storing notification');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification', payload);
      return;
    }

    if (type == 'reaction' || type == 'comment' || type == 'followRequestSend') {
      navigatorKey.currentState?.pushNamed('/notifications');
    } else if (type == 'message') {
      navigatorKey.currentState?.pushNamed('/activity');
    } else if (type == 'call') {
      final callHandler = CallHandler();
      await callHandler.showCallkitIncoming(
        notificationData['callId'] ?? '',
        notificationData['callType'] ?? 'audio',
        notificationData['callerName'] ?? 'Unknown',
        notificationData['profilePic'] ?? '',
      );
    }
  } catch (e) {
    print('Error handling notification payload: $e');
  }
}

void initLocalNotifications() {
  var androidSettings = const AndroidInitializationSettings('ic_notificationn');
  var iosSettings = const DarwinInitializationSettings();
  var initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      print('Notification tapped! Payload: ${response.payload}');
      if (response.payload != null) {
        await _handleNotificationPayload(response.payload!);
      }
    },
  );
}

void setupFirebaseListeners() {
  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("Foreground message received: ${message.notification?.title}");
    Provider.of<NotificationProvider>(navigatorKey.currentContext!, listen: false).showNotification();

    // Handle call notifications immediately
    if (message.data['type'] == 'call') {
      final callHandler = CallHandler();
      await callHandler.showCallkitIncoming(
        message.data['callId'] ?? '',
        message.data['callType'] ?? 'audio',
        message.data['callerName'] ?? 'Unknown',
        message.data['profilePic'] ?? '',
      );
      return;
    }

    // Create payload combining notification and data
    final payload = jsonEncode({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data['data'] ?? jsonEncode(message.data),
    });

    // Get current badge count
    final prefs = await SharedPreferences.getInstance();
    int currentBadgeCount = prefs.getInt('badge_count') ?? 0;
    currentBadgeCount++;
    await prefs.setInt('badge_count', currentBadgeCount);

    // Show notification
    await localNotifications.show(
      currentBadgeCount,
      message.notification?.title ?? 'New notification',
      message.notification?.body ?? '',
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notificationn',
          channelShowBadge: true,
        ),
        iOS: DarwinNotificationDetails(
          badgeNumber: currentBadgeCount,
        ),
      ),
      payload: payload,
    );
  });

  // Background/terminated messages
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print("App opened from notification: ${message.notification?.title}");
    await _handleNotificationPayload(jsonEncode({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data['data'] ?? jsonEncode(message.data),
    }));
  });

  // Initial message when app is launched from terminated state
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async {
    if (message != null) {
      print("App launched from notification: ${message.notification?.title}");
      await _handleNotificationPayload(jsonEncode({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data['data'] ?? jsonEncode(message.data),
      }));
    }
  });
}

Future<void> initCallKit() async {
  await FlutterCallkitIncoming.requestNotificationPermission({
    'alertTitle': 'Permissions required',
    'alertDescription': 'Allow notification access to receive calls',
    'cancelButton': 'Cancel',
    'okButton': 'Ok',
    'foregroundService': {
      'channelId': 'com.ancobridge.ancobridgeonline',
      'channelName': 'Foreground service for incoming calls',
      'notificationTitle': 'Call service is running',
      'notificationIcon': 'ic_notification',
    },
    'selfManaged': {
      'title': 'Permissions required',
    },
  });

  FlutterCallkitIncoming.onEvent.listen((event) async {
    print('🔔 CallKit event received: ${event?.event}');
    print('📦 CallKit event body: ${event?.body}');

    if (event == null) return;

    final callHandler = CallHandler();
    final callId = event.body['id'] ?? '';
    final extra = event.body['extra'] ?? {};
    final callType = extra['callType'] ?? 'audio';
    final callerName = extra['callerName'] ?? 'Unknown';
    final profilePic = extra['profilePic'] ?? '';

    switch (event.event) {
      case Event.actionCallAccept:
        await callHandler.handleAcceptCall(callId, callType, callerName, profilePic);
        break;
      case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE':
      case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TIMEOUT':
      case 'com.hiennv.flutter_callkit_incoming.ACTION_CALL_ENDED':
        await callHandler.endAllCalls();
        await callHandler.handleRejectCall(callId);
        break;
      default:
        print('⚠️ Unhandled CallKit event: ${event.event}');
        break;
    }
  });
}

Future<Widget> getInitialScreen() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String isLoggedIn = prefs.getString('loginstatus') ?? '0';
  String tempuserid = prefs.getString('temp_userid') ?? '';
  String temptoken = prefs.getString('temp_token') ?? '';
  String? userId = prefs.getString('user_id');
  String? token = prefs.getString('user_token');

  if (isLoggedIn == '1') {
    return UserInputFields(userid: tempuserid, token: temptoken);
  } else if (isLoggedIn == '2') {
    return LoginScreen();
  } else if (isLoggedIn == '3' && userId != null && token != null) {
    setupFirebaseListeners();
    initCallKit();
    return BottomNavBarScreen();
  } else {
    return StartScreen();
  }
}

class MyApp extends StatefulWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final CallManager _callManager = CallManager();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _checkPendingNotifications();
    getFCMToken();
  }

  Future<void> _initializeServices() async {
    await _socketService.connect();
    await _callManager.initialize();
  }

  Future<void> _checkPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingNotification = prefs.getString('pending_notification');
    if (pendingNotification != null) {
      await _handleNotificationPayload(pendingNotification);
      await prefs.remove('pending_notification');
    }
  }

  Future<void> getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _socketService.connect();
        _callManager.initialize();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.detached:
        _socketService.disconnect();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppNotification(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [
          routeObserver
        ],
        routes: {
          '/notifications': (_) => NotificationsPage(),
          '/activity': (_) => ChatScreen(),
        },
        theme: ThemeData(brightness: Brightness.light, primaryColor: AppColors.lightPrimary),
        darkTheme: ThemeData(brightness: Brightness.dark, primaryColor: AppColors.darkPrimary),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: widget.initialScreen,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request notification permissions
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    announcement: false,
  );

  print('Notification permission status: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // Get APNS token for iOS (only on real devices)
    if (Platform.isIOS) {
      try {
        // APNS token is only available on real devices, not simulators
        String? apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          print('APNS Token: $apnsToken');
        } else {
          print('APNS Token not available (likely running on simulator)');
        }
      } catch (e) {
        print('Error getting APNS token: $e');
        print('This is normal on iOS simulator');
      }
    }
  }

  initLocalNotifications();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  print("App restarted - loginstatus: ${prefs.getString('loginstatus')}");

  Widget initialScreen = await getInitialScreen();

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserProviderall()),
        ChangeNotifierProvider(create: (_) => ReactionsProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(430, 930),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MyApp(initialScreen: initialScreen);
        },
      ),
    ),
  );
}
