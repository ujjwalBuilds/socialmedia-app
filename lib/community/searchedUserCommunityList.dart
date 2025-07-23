import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/community/communityDetailedScreen.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class UserCommunitiesListView extends StatelessWidget {
  final String userId;
  final UserProviderall userProvider; // Pass your provider here

  const UserCommunitiesListView({
    Key? key,
    required this.userId,
    required this.userProvider,
  }) : super(key: key);

  Future<List<Community>> _fetchUserCommunities(String userId) async {
    if (userId.isEmpty) return [];

    try {
      final token = userProvider.userToken ?? '';
      final currentUserId = userProvider.userId ?? '';

      final headers = {
        'token': token,
        'userid': currentUserId,
        'Content-Type': 'application/json',
      };

      final Uri profileUrl =
          Uri.parse('${BASE_URL}api/showProfile?other=$userId');
      final profileResponse = await http.get(profileUrl, headers: headers);

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        final communityIds =
            List<String>.from(profileData['result'][0]['communities'] ?? []);

        if (communityIds.isEmpty) return [];

        List<Community> fetchedCommunities = [];
        for (String communityId in communityIds) {
          await _fetchCommunityInfo(communityId, headers, fetchedCommunities);
        }
        return fetchedCommunities;
      } else {
        print('Error: ${profileResponse.statusCode} - ${profileResponse.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching communities: $e');
      return [];
    }
  }

  Future<void> _fetchCommunityInfo(String communityId,
      Map<String, String> headers, List<Community> fetchedCommunities) async {
    try {
      final Uri communityUrl =
          Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId');
      final communityResponse = await http.get(
        communityUrl,
        headers: headers,
      );

      if (communityResponse.statusCode == 200) {
        final communityData = json.decode(communityResponse.body);
        fetchedCommunities.add(Community.fromJson(communityData));
      } else {
        print(
            'Error fetching community $communityId: ${communityResponse.statusCode} - ${communityResponse.body}');
      }
    } catch (e) {
      print('Error fetching community $communityId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Community>>(
      future: _fetchUserCommunities(userId), // Use your function here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.twistingDots(
              leftDotColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkText
                  : AppColors.lightText,
              rightDotColor: Color(0xFF7400A5),
              size: 20,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading communities'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No Communities Joined Yet',
              style: GoogleFonts.roboto(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.black54,
                fontSize: 14,
              ),
            ),
          );
        }

        final communities = snapshot.data!;
        return SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.5, // Set a fixed height
          child: ListView.builder(
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return Padding(
                padding:
                    EdgeInsets.only(left: 10.0.w, top: 10.h, right: 10.0.w),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    border: Border.all(color: Color(0xFF7400A5)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF7400A5),
                      backgroundImage: community.profilePicture.isNotEmpty
                          ? NetworkImage(community.profilePicture)
                          : null,
                    ),
                    title: Text(
                      community.name,
                      style: GoogleFonts.roboto(
                        color: Color(0xFF7400A5),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      community.description ?? 'No description',
                      style: GoogleFonts.roboto(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${community.membersCount} Members',
                      style: GoogleFonts.roboto(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CommunityDetailScreen(communityId: community.id),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
