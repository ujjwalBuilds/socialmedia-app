import 'package:flutter/material.dart';
import 'package:flutter_application_kraya/Providers/NotificationService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';


class NotificationBadge extends ConsumerStatefulWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends ConsumerState<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Listen to Firebase messages to update the badge
    listenToNotifications();
  }

  void listenToNotifications() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {});
        listenToNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notificationService.unreadCount;
//  final notificationsAsync = ref.watch(notificationsProvider);
    final Size size = MediaQuery.of(context).size;
    final double iconSize = size.width * 0.06;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => context.push('/notification-screen'),
          child: SvgPicture.asset(
            'assets/icons/notification.svg',
            width: iconSize,
            height: 23.h,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: BoxConstraints(
                minWidth: 12.w,
                minHeight: 10.h,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
