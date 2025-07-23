// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:socialmedia/main.dart';
// import 'package:socialmedia/user_apis/sendrequest.dart';
// import 'package:socialmedia/utils/constants.dart';

// class ProfileModel {
//   final String id;
//   final String name;
//   final int followers;
//   final int followings;
//   final bool isFollowing;
//   final bool requestPending;

//   ProfileModel({
//     required this.id,
//     required this.name,
//     required this.followers,
//     required this.followings,
//     required this.isFollowing,
//     required this.requestPending,
//   });

//   factory ProfileModel.fromJson(Map<String, dynamic> json) {
//     return ProfileModel(
//       id: json['_id'],
//       name: json['name'],
//       followers: json['followers'],
//       followings: json['followings'],
//       isFollowing: json['isFollowing'],
//       requestPending: json['requestPending'],
//     );
//   }
// }

// class Post {
//   final String id;
//   final String? mediaUrl;
//   final String? content;

//   Post({
//     required this.id,
//     this.mediaUrl,
//     this.content,
//   });

//   factory Post.fromJson(Map<String, dynamic> json) {
//     String? mediaUrl;

//     // Check if 'data' exists and contains 'media'
//     if (json.containsKey('data') && json['data'] is Map) {
//       var media = json['data']['media'];

//       if (media is List && media.isNotEmpty) {
//         var firstMedia = media[0]; // Get first media item

//         // Ensure it's a map and contains 'url'
//         if (firstMedia is Map && firstMedia.containsKey('url')) {
//           mediaUrl = firstMedia['url']; // Extract URL
//         }
//       }
//     }

//     return Post(
//       id: json['_id'],
//       mediaUrl: mediaUrl,
//       content: json['data']?['content'], // Safe content extraction
//     );
//   }


// }



// class OtherProfileScreen extends StatefulWidget {
//   final String userId;
//   final String token;
//   final String otherid;

//   const OtherProfileScreen({
//     Key? key,
//     required this.userId,
//     required this.token,
//     required this.otherid
//   }) : super(key: key);

//   @override
//   _OtherProfileScreenState createState() => _OtherProfileScreenState();
// }

// class _OtherProfileScreenState extends State<OtherProfileScreen> {
//   late Future<ProfileModel> profileFuture;
//   late Future<List<Post>> postsFuture;

//   @override
//   void initState() {
//     super.initState();
//     profileFuture = fetchProfile();
//     postsFuture = fetchPosts();
//   }

//   Future<ProfileModel> fetchProfile() async {
//     final response = await http.get(
//       Uri.parse('${BASE_URL}api/showProfile?other=${widget.otherid}'),
//       headers: {
//         'userid': widget.userId,
//         'token': widget.token,
//       },
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       return ProfileModel.fromJson(data['result'][0]);
//     } else {
//       throw Exception('Failed to load profile');
//     }
//   }

//   Future<List<Post>> fetchPosts() async {
//     final response = await http.get(
//       Uri.parse('${BASE_URL}api/get-posts?userId=${widget.otherid}'),
//       headers: {
//         'userid': widget.userId,
//         'token': widget.token,
//       },
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       return (data['posts'] as List)
//           .map((post) => Post.fromJson(post))
//           .where((post) => post.mediaUrl != null) // Filter posts with media only
//           .toList();
//     } else {
//       throw Exception('Failed to load posts');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: FutureBuilder<ProfileModel>(
//         future: profileFuture,
//         builder: (context, profileSnapshot) {
//           if (profileSnapshot.hasError) {
//             return Center(child: Text('Error: ${profileSnapshot.error}'));
//           }

//           if (!profileSnapshot.hasData) {
//             return Center(child: CircularProgressIndicator());
//           }

//           final profile = profileSnapshot.data!;

//           return CustomScrollView(
//             slivers: [
//               SliverToBoxAdapter(
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 40,
//                       backgroundColor: Color(0xFF7400A5).withOpacity(0.2),
//                       child: Text(
//                         profile.name[0].toUpperCase(),
//                         style: TextStyle(fontSize: 30, color: Colors.white),
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       profile.name,
//                       style: GoogleFonts.roboto(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             foregroundColor: Colors.white,
//                             minimumSize: Size(117.w, 34.h),
//                             side: BorderSide(color: Color(0xFFBE75FF), width: 2),
//                           ),
//                           onPressed: () {},
//                           child: Text('Message' , style: TextStyle(color: const Color(0xFFBE75FF)),),
//                         ),
//                         SizedBox(width: 12.w),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xFFBE75FF),
//                             foregroundColor: Colors.white,
//                              minimumSize: Size(117.w, 34.h)
//                           ),
//                           onPressed: () {
                            
//                              sendRequest(widget.userId, widget.token, widget.otherid);
//                           },
//                           child: Text(profile.isFollowing ? 'Following' : 'Add Friend' , style: TextStyle(color: Colors.black),),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _buildStatColumn('followers', profile.followers.toString()),
//                         SizedBox(width: 30),
//                         _buildStatColumn('following', profile.followings.toString()),
//                       ],
//                     ),
//                     SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//               FutureBuilder<List<Post>>(
//                 future: postsFuture,
//                 builder: (context, postsSnapshot) {
//                   if (postsSnapshot.hasError) {
//                     return SliverToBoxAdapter(
//                       child: Center(child: Text('Error: ${postsSnapshot.error}')),
//                     );
//                   }

//                   if (!postsSnapshot.hasData) {
//                     return SliverToBoxAdapter(
//                       child: Center(child: CircularProgressIndicator()),
//                     );
//                   }

//                   return SliverGrid(
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 3,
//                       crossAxisSpacing: 2,
//                       mainAxisSpacing: 2,
//                     ),
//                     delegate: SliverChildBuilderDelegate(
//                       (context, index) {
//                         final post = postsSnapshot.data![index];
//                         return Image.network(
//                           post.mediaUrl!,
//                           fit: BoxFit.cover,
//                         );
//                       },
//                       childCount: postsSnapshot.data!.length,
//                     ),
//                   );
//                 },
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildStatColumn(String label, String count) {
//     return Column(
//       children: [
//         Text(
//           count,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(color: Colors.grey),
//         ),
//       ],
//     );
//   }
// }