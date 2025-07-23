import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glassycontainer/glassycontainer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/chatProvider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/explore_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/post_Screen.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/provider/notification_provider.dart';
import 'package:socialmedia/users/live_stream_screen1.dart';
import 'package:socialmedia/users/notification.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({Key? key}) : super(key: key);

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  String? profilePic;
  Timer? _timer;
  int _selectedIndex = 0;
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
  late UserProviderall userProvider;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    _initializePages();
    _fetchData();
    Future.delayed(Duration.zero, () async {
      await _loadUserProfile();
      await updateFCMToken();
    });
  }

  void _initializePages() {
    _pages = [
      ExplorePage(key: UniqueKey(), forceRefresh: true),
      ChatScreen(),
      const DarkScreenWithBottomModal(),
      const NotificationsPage(),
      const user_profile(),
    ];
  }

  void _fetchData() {
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userid = prefs.getString('user_id');
      final String? token = prefs.getString('user_token');

      if (userid == null || token == null) {
        print('User ID or token is missing');
        return;
      }
      await userProvider.refreshUserProfile(userid, token);
    } catch (error) {
      print('An error occurred while fetching profile: $error');
    }
  }

  Future<void> updateFCMToken() async {
    final url = Uri.parse('${BASE_URL}api/edit-profile');
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final token = userProvider.userToken;
    final userId = userProvider.userId;
    print('edit porifile callhhua');
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $fcmToken");

      if (fcmToken == null) {
        print('FCM token is null. Cannot proceed.');
        return;
      }

      final request = http.MultipartRequest('PUT', url)
        ..headers.addAll({
          'userId': userId!,
          'token': token!,
        });
      request.fields['fcmToken'] = fcmToken;
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('FCM token updated successfully.');
        print('Response: $responseBody');
      } else {
        final responseBody = await response.stream.bytesToString();
        print(
            'Failed to update FCM token. Status Code: ${response.statusCode}');
        print('Error: $responseBody');
      }
    } catch (e) {
      print('An error occurred while updating FCM token: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      postsProvider.resetPosts();
      setState(() {
        _initializePages();
        _selectedIndex = 0;
      });
      if (userProvider.userId != null && userProvider.userToken != null) {
        print('Refreshing entire home screen');
        postsProvider.fetchPosts(userProvider.userId!, userProvider.userToken!, forceRefresh: true);
      }
      _loadUserProfile();
    } else if (index == 1) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.reset();
      setState(() {
        _initializePages();
        _selectedIndex = 1;
      });
      chatProvider.fetchChatRooms();
      _loadUserProfile();
    } else {
      if (_selectedIndex != index) {
        _loadUserProfile();
      }
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShowNotificationIndicator = context.watch<NotificationProvider>().hasNotification;

    return Consumer<UserProviderall>(
      builder: (context, userProvider, child) {
        final ThemeData theme = Theme.of(context);
        final Color activeColor =
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF7400A5)
                : Colors.deepPurpleAccent;
        final Color inactiveColor =
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54;
        final Color bgColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900.withOpacity(0.95)
            : Colors.white.withOpacity(0.95);

        return WillPopScope(
          onWillPop: () async {
            if (_selectedIndex != 0) {
              setState(() {
                _selectedIndex = 0;
              });
              return false;
            }
            bool? shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'Exit App',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'Are you sure you want to exit?',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                      postsProvider.resetPosts();
                      SystemNavigator.pop();
                    },
                    child: Text(
                      'Exit',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
            return shouldExit ?? false;
          },
          child: SafeArea(
            child: Scaffold(
              body: _pages[_selectedIndex],
              extendBody: true,
              bottomNavigationBar: Stack(
                children: [
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: SafeArea(
                        child: Container(
                          height: 80.h,
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border(
                              top: BorderSide(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80.h,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                              icon: Iconsax.home,
                              label: '',
                              index: 0,
                              isNotifierItem: false,
                              showDot: shouldShowNotificationIndicator,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor),
                          _buildNavItem(
                              icon: Iconsax.message,
                              label: '',
                              index: 1,
                              isNotifierItem: false,
                              showDot: shouldShowNotificationIndicator,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor),
                          _buildNavItem(
                              icon: Iconsax.add_circle,
                              label: '',
                              index: 2,
                              isNotifierItem: false,
                              showDot: shouldShowNotificationIndicator,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor),
                          _buildNavItem(
                              icon: Iconsax.notification,
                              label: '',
                              index: 3,
                              isNotifierItem: true,
                              showDot: shouldShowNotificationIndicator,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor),
                          _buildNavItem(
                              icon: Icons.circle,
                              label: '',
                              index: 4,
                              isNotifierItem: false,
                              showDot: shouldShowNotificationIndicator,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
      {required IconData icon,
      required String label,
      required int index,
      required bool isNotifierItem,
      required bool showDot,
      required Color activeColor,
      required Color inactiveColor}) {
    bool isSelected = _selectedIndex == index;

    if (index == 4) {
      return Consumer<UserProviderall>(
        builder: (context, userProviderData, child) {
          return Expanded(
            child: InkWell(
              onTap: () => _onItemTapped(index),
              splashColor: activeColor.withOpacity(0.1),
              highlightColor: activeColor.withOpacity(0.05),
              child: ZoomTapAnimation(
                onTap: () => _onItemTapped(index),
                child: Container(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 18.sp,
                            backgroundColor:
                                isSelected ? activeColor : Colors.transparent,
                            child: CircleAvatar(
                              radius: 15.3.sp,
                              backgroundColor:
                                  Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                              child: userProviderData.getCurrentProfilePicture() != null
                                  ? ClipOval(
                                      child: Image.network(
                                        userProviderData.getCurrentProfilePicture()!,
                                        fit: BoxFit.cover,
                                        width: 26.sp,
                                        height: 26.sp,
                                        errorBuilder: (context, error, stackTrace) {
                                          return ClipOval(
                                            child: SvgPicture.asset(
                                              'assets/icons/profile.svg',
                                              width: 23.sp,
                                              height: 23.sp,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : ClipOval(
                                      child: SvgPicture.asset(
                                        'assets/icons/profile.svg',
                                        width: 23.sp,
                                        height: 23.sp,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: GoogleFonts.roboto(
                              color: isSelected ? activeColor : inactiveColor,
                              fontSize: 12.sp,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        splashColor: activeColor.withOpacity(0.1),
        highlightColor: activeColor.withOpacity(0.05),
        child: ZoomTapAnimation(
          onTap: () => _onItemTapped(index),
          child: SizedBox(
            height: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? (isSelected ? activeColor : Colors.white)
                          : (isSelected ? activeColor : Colors.black),
                      size: 30.sp,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.roboto(
                        color: isSelected ? activeColor : inactiveColor,
                        fontSize: 12.sp,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ],
                ),
                if (isNotifierItem && showDot)
                  Positioned(
                    top: 10.h,
                    child: Transform.translate(
                      offset: const Offset(10, 0),
                      child: Container(
                        width: 10.w,
                        height: 10.h,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DarkScreenWithBottomModal extends StatefulWidget {
  const DarkScreenWithBottomModal({super.key});

  @override
  _DarkScreenWithBottomModalState createState() =>
      _DarkScreenWithBottomModalState();
}

class _DarkScreenWithBottomModalState extends State<DarkScreenWithBottomModal> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showCustomBottomSheet(context);
      }
    });
  }

  void showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.lightText
          : AppColors.darkText,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const BottomNavBarScreen()),
            );
            return false;
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Choose Option",
                        style: GoogleFonts.poppins(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBarScreen())),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PostScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.darkText,
                      side: const BorderSide(
                        color: Color(0xFF7400A5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Make a Post",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LiveStreamScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromARGB(19, 255, 255, 255)
                              : AppColors.darkText,
                      side: const BorderSide(
                        color: Colors.greenAccent,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Go Live",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
         Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
        );
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.lightText
              : Colors.white38,
        ),
      ),
    );
  }
}
