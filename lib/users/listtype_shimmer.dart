import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final bool isNotification;

  const ShimmerList({Key? key, this.itemCount = 20, this.isNotification = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Avatar Placeholder
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.white24,
                ),
              ),
              SizedBox(width: 12.w),
              // Title & Subtitle placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title shimmer placeholder
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 16.h,
                        width: 200.w,
                        color: Colors.white24,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Subtitle shimmer placeholder
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade500,
                      child: Container(
                        height: 14.h,
                        width: 150.w,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing buttons placeholders
              
            ],
          ),
        );
      },
    );
  }
}
