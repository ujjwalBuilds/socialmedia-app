import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/utils/constants.dart';

class AddFriendsBottomSheet extends StatefulWidget {
  final Map<String, Participant> participantsMap;
  final Function(String userId) onInvite;
  final List<String> excludeUserIds;

  const AddFriendsBottomSheet({
    Key? key,
    required this.participantsMap,
    required this.onInvite,
    this.excludeUserIds = const [],
  }) : super(key: key);

  @override
  State<AddFriendsBottomSheet> createState() => _AddFriendsBottomSheetState();
}

class _AddFriendsBottomSheetState extends State<AddFriendsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    // Filter out participants already in the call
    final availableParticipants = widget.participantsMap.values.where((p) => !widget.excludeUserIds.contains(p.userId)).toList();

    if (availableParticipants.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Friends to the Call',
              style: GoogleFonts.roboto(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'All contacts are already in the call',
              style: GoogleFonts.roboto(
                fontSize: 16.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Friends to the Call',
            style: GoogleFonts.roboto(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24.h),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: min(availableParticipants.length, 5), // Limit to 5 for UI
            itemBuilder: (context, index) {
              final participant = availableParticipants[index];
              // Generate random phone numbers for demo

              return ContactTile(
                name: participant.name ?? 'Unknown User',
                profilePic: participant.profilePic,
                onInvite: () => widget.onInvite(participant.userId),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ContactTile extends StatefulWidget {
  final String name;

  final String? profilePic;
  final VoidCallback onInvite;

  const ContactTile({
    Key? key,
    required this.name,
    this.profilePic,
    required this.onInvite,
  }) : super(key: key);

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  @override
  Widget build(BuildContext context) {
    late UserProviderall userProvider;

    void initState() {
      super.initState();
      userProvider = Provider.of<UserProviderall>(context, listen: false);
      userProvider.loadUserData().then((_) {
        setState(() {}); // Refresh UI after loading data
      });
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                //  color: Colors.green,
                width: 2,
              ),
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: widget.profilePic != null
                    ? Image.network(
                        widget.profilePic!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
                      )
                    : Image.asset('assets/avatar/7.png')),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7400A5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            child: Text(
              'INVITE',
              style: GoogleFonts.roboto(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: Colors.green.withOpacity(0.3),
      child: Center(
        child: Text(
          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
