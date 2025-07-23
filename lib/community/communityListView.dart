import 'dart:convert';
import 'dart:developer' show log;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/post_Screen.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/community/communityDetailedScreen.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/community/communityProvider.dart';
import 'package:socialmedia/users/listtype_shimmer.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';

class CommunitiesListView extends StatefulWidget {
  @override
  _CommunitiesListViewState createState() => _CommunitiesListViewState();
}

class _CommunitiesListViewState extends State<CommunitiesListView> {
  bool isLoading = true;
  List<Community> communities = [];
  Map<String, int> communityMemberCounts = {};

  @override
  void initState() {
    super.initState();
    fetchUserCommunities();
  }

  Future<void> _fetchCommunityInfo(String communityId, List<Community> fetchedCommunities) async {
    try {
      final Uri communityUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId');
      final userId = Provider.of<UserProviderall>(context, listen: false).userId ?? '';
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';

      // Set headers with authorization token
      final headers = {
        'token': token,
        'userId': userId,
        'Content-Type': 'application/json',
      };
      final communityResponse = await http.get(
        communityUrl,
        headers: headers,
      );

      if (communityResponse.statusCode == 200) {
        final communityData = json.decode(communityResponse.body);
        fetchedCommunities.add(Community.fromJson(communityData));
        log(communityData.toString());
      } else {
        print('Error fetching community $communityId: ${communityResponse.statusCode} - ${communityResponse.body}');
      }
    } catch (e) {
      print('Error fetching community $communityId: $e');
    }
  }

  Future<void> fetchUserCommunities() async {
    final userId = Provider.of<UserProviderall>(context, listen: false).userId;

    if (userId != null) {
      try {
        // Get token from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token') ?? '';

        // Set headers with authorization token
        final headers = {
          'token': token,
          'userId': userId,
          'Content-Type': 'application/json',
        };

        // Make a single API call to fetch all user communities at once
        final Uri communitiesUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/user-communities');
        final response = await http.get(
          communitiesUrl,
          headers: headers,
        );

        if (response.statusCode == 200) {
          print("this is communities URL ---  ${communitiesUrl}");
          final data = json.decode(response.body);
          // log(data.toString());
          // Parse the communities from the response
          final communityList = data['communities'] as List;
          List<Community> fetchedCommunities = communityList.map((communityJson) => Community.fromJson(communityJson)).toList();
          setState(() {
            communities = fetchedCommunities;
            isLoading = false;
          });
        } else {
          print('Error fetching communities: ${response.statusCode} - ${response.body}');
          setState(() => isLoading = false);
        }
      } catch (e) {
        print('Error fetching communities: $e');
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }

    // Debug print for communities
    for (var c in communities) {
      print('Comm%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%unity: ${c.name}, Profile^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^Pic: ${c.profilePicture}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: LoadingAnimationWidget.twistingDots(leftDotColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, rightDotColor: Color(0xFF7400A5), size: 20),
      );
    }

    if (communities.isEmpty) {
      return Center(
        child: Text(
          'No Communities Joined Yet',
          style: GoogleFonts.roboto(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    }

    // Fetch community details when the list is built
    for (var community in communities) {
      _fetchAndLogCommunityDetails(community);
    }

    return ListView.builder(
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return Padding(
          padding: EdgeInsets.only(left: 10.0.w, top: 10.h, right: 10.0.w),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                border: Border.all(
                  color: Color(0xFF7400A5),
                )),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24.r,
                backgroundColor: Color(0xFF7400A5),
                backgroundImage: community.profilePicture.isNotEmpty ? NetworkImage(community.profilePicture) : null,
                child: community.profilePicture.isEmpty
                    ? Text(
                        community.name.isNotEmpty ? community.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
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
                '${communityMemberCounts[community.id] ?? 0} Members',
                style: GoogleFonts.roboto(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityScreen(communityId: community.id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchAndLogCommunityDetails(Community community) async {
    try {
      final Uri communityUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/${community.id}');
      final userId = Provider.of<UserProviderall>(context, listen: false).userId ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';

      final headers = {
        'token': token,
        'userId': userId,
        'Content-Type': 'application/json',
      };

      final communityResponse = await http.get(communityUrl, headers: headers);

      if (communityResponse.statusCode == 200) {
        final communityData = json.decode(communityResponse.body);
        // log('Community Details for ${community.name}: ${communityData.toString()}');

        // Count members and update the state
        if (communityData['members'] != null) {
          final membersCount = (communityData['members'] as List).length;
          setState(() {
            communityMemberCounts[community.id] = membersCount;
          });
        }
      } else {
        // log('Error fetching details for community ${community.id}: ${communityResponse.statusCode}');
      }
    } catch (e) {
      // log('Error fetching community details: $e');
    }
  }
}
