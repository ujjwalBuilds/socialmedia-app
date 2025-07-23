import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/services/provider/notification_provider.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/user_apis/acceptrequest.dart';
import 'package:socialmedia/user_apis/fetch_notification.dart';
import 'package:socialmedia/user_apis/rejectrequest.dart';
import 'package:socialmedia/users/listtype_shimmer.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/users/show_post_content.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:tab_container/tab_container.dart';
import 'package:http/http.dart' as http;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> friendRequests;
  late Future<List<dynamic>> notificationsList;
  late Future<List<dynamic>> combinedNotifications;
  late Future<List<dynamic>> SentfriendRequests;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    markNotificationsAsSeen();
    Provider.of<NotificationProvider>(context, listen: false).clearNotification();
  }

  Future<void> markNotificationsAsSeen() async {
    try {
      // Fetch userId and token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? token = prefs.getString('user_token');

      if (userId == null || token == null) {
        print('User ID or Token is missing');
        return;
      }

      // API Endpoint
      final url = Uri.parse('${BASE_URL}api/mark-as-seen');

      // Request Body
      Map<String, dynamic> body = {
        'markAll': "true",
      };

      // Make POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'userId': userId, // Include userId in headers
        },
        body: jsonEncode(body),
      );

      // Handle Response
      if (response.statusCode == 200) {
        print('Notifications marked as seen successfully');
      } else {
        print('Failed to mark notifications as seen: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notifications as seen: $e');
    }
  }

  void fetchNotifications() {
    setState(() {
      friendRequests = fetchFriendRequests();
      notificationsList = fetchAllNotifications();
      combinedNotifications = _getCombinedNotifications();
      SentfriendRequests = fetchSentFriendRequests();
    });
  }

  Future<List<dynamic>> fetchAllNotifications() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-notifications?page=1&limit=20'),
        headers: {
          'Content-Type': 'application/json',
          'token': userProvider.userToken ?? '',
          'userId': userProvider.userId ?? '',
        },
      );
      log("All NOtifs: " + response.body.toString());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Combine unseen and seen notifications
        List<dynamic> allNotifications = [];
        if (data['data']['unseen'] != null) {
          allNotifications.addAll(data['data']['unseen']);
        }
        if (data['data']['seen'] != null) {
          allNotifications.addAll(data['data']['seen']);
        }
        return allNotifications;
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<List<dynamic>> _getCombinedNotifications() async {
    try {
      final requests = await friendRequests;
      final notifications = await notificationsList;

      // Prepare friend requests with uniform format
      final formattedRequests = requests.map((request) {
        return {
          '_id': request['_id'],
          'type': 'friendRequest',
          'sender': {
            'id': request['_id'],
            'name': request['name'],
            'profilePic': request['profilePic']
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'requestData': request
        };
      }).toList();

      // Combine both lists
      List<dynamic> combined = [...formattedRequests, ...notifications];

      // Sort by timestamp in descending order (newest first)
      combined.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      return combined;
    } catch (e) {
      print('Error combining notifications: $e');
      return [];
    }
  }

  Future<void> _startChat(String participantId) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
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
    } catch (e) {}
  }

  Future<void> _refreshNotifications() async {
    fetchNotifications();
  }

  void handleAccept(String id) async {
    await acceptRequest(id);
    await _startChat(id);
    fetchNotifications();
  }

  void handleDecline(String id) async {
    await rejectRequest(id);
    fetchNotifications();
  }

  void handleDeleteSentRequest(String id) async {
    try {
      await deleteSentRequest(id);
      fetchNotifications(); // Refresh the list after deletion
    } catch (e) {
      print("Error deleting sent request: $e");
      // You might want to show a snackbar or alert here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete sent request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String capitalizeEachWord(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final response = await http.delete(
        Uri.parse(
            '${BASE_URL}api/delete-notification?notificationId=$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
          'Authorization': 'Basic Og==',
        },
      );

      if (response.statusCode == 200) {
        // Refresh notifications after successful deletion
        fetchNotifications();
      } else {
        print('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void _clearAllNotifications() async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);

      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-notification?clearAll=1'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
          'Authorization': 'Basic Og==',
        },
      );


      if (response.statusCode == 200) {
        print('Successfully cleared all notifications');
        // Refresh notifications after successful deletion
        setState(() {
          combinedNotifications = Future.value([]);
        });
        fetchNotifications();

        // Show success message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Failed to clear notifications: ${response.statusCode}');
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error clearing notifications: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.lightText
              : AppColors.darkText,
          appBar: AppBar(
            title: Text(
              "Notifications",
              style: GoogleFonts.roboto(fontSize: 18.sp),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.lightText
                : AppColors.darkText,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText
                      : AppColors.lightText),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BottomNavBarScreen(),
                  ),
                );
              },
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.more_vert),
            //     onPressed: () {},
            //   ),
            // ],
            actions: [
              // TextButton(
              //   child: Text("Clear All", style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
              //   onPressed: _clearAllNotifications,
              // ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0.w),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Color(0xFFC08EF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      side: BorderSide(color: Color(0xFF7400A5), width: 2.0),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 12.h), // <-- Add this line
                  ),
                  child: Text(
                    "Clear All",
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 10.sp),
                  ),
                  onPressed: _clearAllNotifications,
                ),
              ),
            ],
          ),
          body: TabContainer(
            tabMaxLength: 100,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade600
                : Colors.grey.shade300,
            selectedTextStyle: GoogleFonts.roboto(
              fontSize: 18.sp,
            ),
            unselectedTextStyle: GoogleFonts.roboto(
              fontSize: 16.sp,
            ),
            tabs: [
              Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Requests', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sent', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Calls', style: TextStyle(fontWeight: FontWeight.bold))
            ],
            children: [
              combinedNotificationsList(context),
              friendrequestlist(context),
              friendrequestlist(context, isSent: true),
              callloglist(context)
            ],
          )),
    );
  }

  Container combinedNotificationsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.black,
                  Colors.black
                ]
              : [Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        backgroundColor: Color(0xFF7400A5),
        child: FutureBuilder<List<dynamic>>(
          future: combinedNotifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ShimmerList(
                isNotification: true,
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No Notifications",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemType = item['type'];

                // Format timestamp to readable date
                final timestamp =
                    DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
                final formattedTime =
                    DateFormat('MMM d, h:mm a').format(timestamp);

                // If it's a friend request
                if (itemType == 'friendRequest') {
                  final request = item['requestData'];
                  final String profile = item['sender']['profilePic'] ?? '';
                  return GestureDetector(
                    onTap: () {
                      print(item);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  UserProfileScreen(userId: item['_id'])));
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8.r),
                      child: Card(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.transparent
                            : Colors.white,
                        // borderOnForeground: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          side:
                              BorderSide(color: Color(0xFF7400A5), width: 1.5),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(profile),
                            radius: 24.r,
                          ),
                          title: Text(
                            "${request['name']}",
                            style: GoogleFonts.roboto(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  handleAccept(request['_id']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF7400A5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                ),
                                child: Text(
                                  "+ Accept",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 10.w,
                                  ),
                                ),
                                onPressed: () {
                                  handleDecline(request['_id']);
                                },
                                child: Text(
                                  "Decline",
                                  style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              // IconButton(
                              //   icon: Icon(Icons.delete_outline,
                              //     color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              //     size: 20.sp,
                              //   ),
                              //   onPressed: () {
                              //     deleteNotification(request['_id']);
                              //   },
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (itemType == 'call') {
                  final String notificationText = capitalizeEachWord(
                      item['details']?['notificationText'] ?? 'Call ended');
                  final String callby =
                      capitalizeEachWord(item['sender']?['name'] ?? 'Unknown');
                  final String typeofcall = capitalizeEachWord(
                      item['details']?['callDetails']?['type'] ?? 'audio');
                  final String profile = item['sender']?['profilePic'] ?? '';
                  final String senderId = item['sender']?['id'] ?? '';

                  return Padding(
                    padding: EdgeInsets.all(2.r),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            if (senderId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserProfileScreen(userId: senderId),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            backgroundImage: profile.isNotEmpty
                                ? NetworkImage(profile)
                                : AssetImage('assets/avatar/8.png')
                                    as ImageProvider,
                            radius: 24.r,
                          ),
                        ),
                        title: Text(
                          '$typeofcall $notificationText - $callby',
                          style: GoogleFonts.roboto(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (itemType == 'like')
                              Icon(Icons.favorite, color: Colors.red)
                            else if (itemType == 'comment')
                              Icon(Icons.comment, color: Color(0xFF7400A5)),
                            SizedBox(width: 8.w),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                deleteNotification(item['_id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                // If it's a regular notification (like, comment, etc.)
                else {
                  final String notificationText = capitalizeEachWord(
                      item['details']?['notificationText'] ??
                          'New notification');
                  final String content = item['details']?['content'] ?? '';
                  final String profile = item['sender']?['profilePic'] ?? '';
                  final String senderId = item['sender']?['id'] ?? '';
                  final feedid = item['details']?['entity']?['feedId'] ?? '';

                  return Padding(
                    padding: EdgeInsets.all(2.r),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (feedid.isNotEmpty) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PostDetailsScreen(feedId: feedid)));
                          }
                        },
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              if (senderId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserProfileScreen(userId: senderId),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              backgroundImage: profile.isNotEmpty
                                  ? NetworkImage(profile)
                                  : AssetImage('assets/avatar/8.png')
                                      as ImageProvider,
                              radius: 24.r,
                            ),
                          ),
                          title: Text(
                            notificationText,
                            style: GoogleFonts.roboto(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (content.isNotEmpty)
                                Text(
                                  content,
                                  style: TextStyle(fontSize: 12.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (itemType == 'like')
                                Icon(Icons.favorite, color: Colors.red)
                              else if (itemType == 'comment')
                                Icon(Icons.comment, color: Color(0xFF7400A5)),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  size: 20.sp,
                                ),
                                onPressed: () {
                                  deleteNotification(item['_id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Container callloglist(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.black,
                  Colors.black
                ]
              : [Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        backgroundColor: Color(0xFF7400A5),
        child: FutureBuilder<List<dynamic>>(
          future: getCallLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No Calls",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            final callItems = snapshot.data!;

            return ListView.builder(
              itemCount: callItems.length,
              itemBuilder: (context, index) {
                final item = callItems[index];

                final timestamp = DateTime.fromMillisecondsSinceEpoch(
                    item['timestamp'] ?? DateTime.now().millisecondsSinceEpoch);
                final formattedTime =
                    DateFormat('MMM d, h:mm a').format(timestamp);

                final String notificationText = capitalizeEachWord(
                    item['details']?['notificationText'] ?? 'Call ended');
                final String callBy =
                    capitalizeEachWord(item['sender']?['name'] ?? 'Unknown');
                final String callType = capitalizeEachWord(
                    item['details']?['callDetails']?['type'] ?? 'audio');
                final String profile = item['sender']?['profilePic'] ?? '';
                final String senderId = item['sender']?['id'] ?? '';

                return Padding(
                  padding: EdgeInsets.all(2.r),
                  child: Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.transparent
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          if (senderId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfileScreen(userId: senderId),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          backgroundImage: profile.isNotEmpty
                              ? NetworkImage(profile)
                              : AssetImage('assets/avatar/8.png')
                                  as ImageProvider,
                          radius: 24.r,
                        ),
                      ),
                      title: Text(
                        '$callType Call - $callBy',
                        style: GoogleFonts.roboto(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                        ),
                      ),
                      subtitle: Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          size: 20.sp,
                        ),
                        onPressed: () {
                          deleteNotification(item['_id']);
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Function to filter only calls from combinedNotifications
  Future<List<dynamic>> getCallLogs() async {
    final allNotifications = await combinedNotifications;
    final callLogs =
        allNotifications.where((item) => item['type'] == 'call').toList();

    // Debugging: Print the number of filtered calls
    print('Filtered Call Logs Count: ${callLogs.length}');
    return callLogs;
  }

  Container friendrequestlist(BuildContext context, {bool isSent = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.black,
                  Colors.black
                ]
              : [Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        backgroundColor: Color(0xFF7400A5),
        child: FutureBuilder<List<dynamic>>(
          future: isSent ? SentfriendRequests : friendRequests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  isSent ? "No Sent Requests" : "No New Requests",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            final requests = snapshot.data!;
            final items = snapshot.data!;

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemType = item['type'];
                final request = items[index];
                final String profile = request['profilePic'] ?? '';
                // Format timestamp to readable date
                final timestamp = DateTime.now();
                final formattedTime =
                    DateFormat('MMM d, h:mm a').format(timestamp);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                UserProfileScreen(userId: request['_id'])));
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.r),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Colors.white,
                      // borderOnForeground: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(profile),
                          radius: 24.r,
                        ),
                        title: Text(
                          "${request['name']}",
                          style: GoogleFonts.roboto(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isSent) ...[
                              ElevatedButton(
                                onPressed: () {
                                  handleAccept(request['_id']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF7400A5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                ),
                                child: Text(
                                  "+ Accept",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.red,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 10.w,
                                  ),
                                ),
                                onPressed: () {
                                  handleDecline(request['_id']);
                                },
                                child: Text(
                                  "Decline",
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.red,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ] else ...[
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.red,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 10.w,
                                  ),
                                ),
                                onPressed: () {
                                  // Cancel sent request
                                  handleDeleteSentRequest(request['_id']);
                                },
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            if (itemType == 'like')
                              Icon(Icons.favorite, color: Colors.red)
                            else if (itemType == 'comment')
                              Icon(Icons.comment, color: Color(0xFF7400A5)),
                            SizedBox(width: 8.w),
                            isSent
                                ? SizedBox()
                                : IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                      size: 20.sp,
                                    ),
                                    onPressed: () {
                                      deleteNotification(request['_id']);
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
