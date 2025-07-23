import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/community/communityApiService.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:shimmer/shimmer.dart';
import 'community.dart';

class SuggestedCommunitiesWidget extends StatefulWidget {
  const SuggestedCommunitiesWidget({Key? key}) : super(key: key);

  @override
  State<SuggestedCommunitiesWidget> createState() => _SuggestedCommunitiesWidgetState();
}

class _SuggestedCommunitiesWidgetState extends State<SuggestedCommunitiesWidget> {
  late Future<List<Community>> futureCommunities;

  @override
  void initState() {
    super.initState();
    futureCommunities = CommunityService.fetchCommunities();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.h, // Increased height to accommodate profile image
      child: FutureBuilder<List<Community>>(
        future: futureCommunities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No communities available.'));
          }

          final communities = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return _buildSuggestedCommunity(community, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5, // Show 5 shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!.withOpacity(0.5),
          highlightColor: Colors.grey[100]!.withOpacity(0.5),
          child: Container(
            width: 120.w,
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 14.h,
                  width: 80.w,
                  color: Colors.white,
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 10.h,
                  width: 60.w,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedCommunity(Community community, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(communityId: community.id),
          ),
        ).then((_) {
          // Optional: refresh the suggested communities list when returning
          setState(() {
            futureCommunities = CommunityService.fetchCommunities();
          });
        });
      },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color.fromARGB(31, 27, 27, 27).withOpacity(0.9),
          image: community.backgroundImage.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(community.backgroundImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30.r,
              backgroundColor: Colors.grey[300],
              backgroundImage: community.profilePicture.isNotEmpty ? NetworkImage(community.profilePicture) : null,
              child: community.profilePicture.isEmpty
                  ? Text(
                      community.name.isNotEmpty ? community.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0.w),
              child: Text(
                community.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0.w),
              child: Text(
                '${community.membersCount} Members',
                style: GoogleFonts.roboto(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
