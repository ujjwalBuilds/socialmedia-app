import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_kraya/Providers/NotificationService.dart';
import 'package:flutter_application_kraya/components/customAppBar.dart';
import 'package:flutter_application_kraya/features/Main/models/notificationModel.dart';

import 'package:flutter_application_kraya/utils/constants/url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';



class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.markAllAsRead();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.notifications;
    print('Notifications: ${notifications.length}'); // Debugging line to check notifications count

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for better contrast
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: LayoutBuilder(
          builder: (context, constraints) {
            double titleFontSize = constraints.maxWidth > 600
                ? 26.0
                : constraints.maxWidth > 350
                    ? 24.0
                    : 22.0;

            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      'assets/icons/back_arrow.svg',
                      width: 15,
                      height: 16,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: const Color(0xFF7C54E9),
                    fontWeight: FontWeight.w600,
                    fontSize: titleFontSize,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              color: Color(0xFF7C54E9),
              onPressed: _showClearConfirmationDialog,
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body: notifications.isEmpty ? _buildEmptyState() : _buildNotificationList(notifications),
    );
  }

  // Empty state widget when no notifications are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/noNotifications.svg', // <-- update with your SVG path
            width: 64,
            height: 64,
            color: Colors.grey, // Optional: tint the SVG
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You will see your notifications here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Build the list of notifications
  Widget _buildNotificationList(List<NotificationModel> notifications) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  // Build individual notification item with modern design
  Widget _buildNotificationItem(NotificationModel notification) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedDate = dateFormat.format(notification.timestamp);

    // Calculate relative time (e.g., "2 hours ago", "1 day ago")
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        // Delete notification with proper ID
        _notificationService.deleteNotification(notification.id ?? '');
        setState(() {});

        // Show snackbar with undo option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF7C54E9),
              onPressed: () {
                // Add notification back (implement restore functionality)
                // _notificationService.restoreNotification(notification);
                setState(() {});
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
          // Add subtle border for unread notifications
          border: notification.isRead
              ? null
              : Border.all(
                  color: const Color(0xFF7C54E9).withOpacity(0.2),
                  width: 1,
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Mark as read if not already read
              if (!notification.isRead) {
                _notificationService.markAsRead(notification.id ?? '');
                setState(() {});
              }

              // Handle notification navigation based on data
              if (notification.data != null && notification.data!.isNotEmpty) {
                _handleNotificationNavigation(notification);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification indicator dot or icon
                  // Container(
                  //   width: 12,
                  //   height: 12,
                  //   margin: const EdgeInsets.only(top: 4),
                  //   decoration: BoxDecoration(
                  //     color: notification.isRead ? Colors.grey[300] : const Color(0xFF7C54E9),
                  //     shape: BoxShape.circle,
                  //   ),
                  // ),
                  // const SizedBox(width: 16),

                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with close button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title ?? 'New notification',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: notification.isRead ? FontWeight.bold : FontWeight.bold,
                                  color: const Color(0xFF7C54E9),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            // Close button (X)
                            GestureDetector(
                              onTap: () {
                                _notificationService.deleteNotification(notification.id ?? '');
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.all(1.sp),
                                child: Icon(
                                  Icons.close,
                                  size: 20.sp,
                                  color: Color(0xFF7C54E9),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Message content
                        Text(
                          notification.message ?? 'New notification body',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                            height: 1.2.h,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // Time information
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Exact time
                            // Text(
                            //   formattedDate,
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     color: Colors.grey[400],
                            //     fontWeight: FontWeight.w400,
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Calculate relative time ago (e.g., "2 hours ago", "1 day ago")
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  // Handle navigation when notification is tapped
  void _handleNotificationNavigation(NotificationModel notification) {
    // Navigate based on notification type stored in data
    if (notification.data != null) {
      final String? type = notification.data!['type'] as String?;

      switch (type) {
        case 'order':
          final String? orderId = notification.data!['order_id'] as String?;
          if (orderId != null) {
            print('Navigating to order details: $orderId');
            // Navigator.pushNamed(context, '/orders/details', arguments: orderId);
          }
          break;

        case 'message':
          print('Navigating to messages');
          // Navigator.pushNamed(context, '/messages');
          break;

        case 'promotion':
          final String? promoId = notification.data!['promo_id'] as String?;
          if (promoId != null) {
            print('Navigating to promotion: $promoId');
            // Navigator.pushNamed(context, '/promotions/details', arguments: promoId);
          }
          break;

        case 'reminder':
          print('Navigating to reminders');
          // Navigator.pushNamed(context, '/reminders');
          break;

        default:
          print('Unknown notification type: $type');
          break;
      }
    }
  }

  // Show confirmation dialog before clearing all notifications
  Future<void> _showClearConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Clear All Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF7C54E9),
            ),
          ),
          content: const Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  color: Color.fromARGB(255, 199, 13, 0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                _notificationService.clearAllNotifications();
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}
