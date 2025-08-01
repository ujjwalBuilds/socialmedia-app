import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/detailed_chat_page.dart';
import 'package:socialmedia/bottom_nav_bar/activity/find_following_start_chat.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/creategroupscreen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/editgroupscreen.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
// // Import the new screen

// class Particiapntgrp extends StatefulWidget {
//   final String chatRoomId;

//   const Particiapntgrp({super.key, required this.chatRoomId});

//   @override
//   State<Particiapntgrp> createState() => _ParticiapntgrpState();
// }

// class _ParticiapntgrpState extends State<Particiapntgrp> {
//   List<dynamic> participants = [];
//   String? adminId;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchChatRoomDetails();
//   }

//   /// Fetch Chat Room Details
//   Future<void> fetchChatRoomDetails() async {
//     try {
//       final userProvider = Provider.of<UserProviderall>(context, listen: false);
//       final String? userId = userProvider.userId;

//       final String? token = userProvider.userToken;

//       if (userId == null || token == null) {
//         throw Exception("User credentials not found.");
//       }

//       print(userId); // Debug print moved here
//       print('##########################################################################################################');
//       print(widget.chatRoomId);
//       print('********************************************************&&&&&&&&&&&&&');
//       final response = await http.get(
//         Uri.parse("${BASE_URL}api/get-chatroom-details?chatRoomId=${widget.chatRoomId}"),
//         headers: {
//           'userId': userId,
//           'token': token,
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           participants = data["chatRoom"]["participants"];
//           adminId = data["chatRoom"]["admin"]; // Store Admin ID
//           isLoading = false;
//         });
//       } else {
//         throw Exception("Failed to load chat room details");
//       }
//     } catch (error) {
//       print("Error fetching chat room details: $error");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   /// Remove a participant from the chatroom
//   Future<void> removeParticipant(String participantId) async {
//     try {
//       final userProvider = Provider.of<UserProviderall>(context, listen: false);
//       final String? userId = userProvider.userId;
//       final String? token = userProvider.userToken;

//       if (userId == null || token == null) {
//         throw Exception("User credentials not found.");
//       }

//       final response = await http.post(
//         Uri.parse("${BASE_URL}api/remove-participant"),
//         headers: {
//           'userId': userId,
//           'token': token,
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           "chatRoomId": widget.chatRoomId,
//           "participant": participantId,
//         }),
//       );

//       if (response.statusCode == 200) {
//         // Successfully removed, update the UI
//         setState(() {
//           participants.removeWhere((user) => user["userId"] == participantId);
//         });

//         Fluttertoast.showToast(
//           msg: "Participant removed successfully!",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.black,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//       } else {
//         throw Exception("Failed to remove participant");
//       }
//     } catch (error) {
//       print("Error removing participant: $error");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to remove participant: $error")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProviderall>(context, listen: false);
//     final String? currentUserId = userProvider.userId;
//     final bool isAdmin = adminId == currentUserId;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Participants',
//           style: GoogleFonts.roboto(fontSize: 18),
//         ),
//         actions: isAdmin
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => EditGroupScreen(chatRoomId: widget.chatRoomId),
//                       ),
//                     );
//                   },
//                 )
//               ]
//             : [],
//       ),
//       body: Container(
//         width: double.infinity,
//         height: MediaQuery.of(context).size.height,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: Theme.of(context).brightness == Brightness.dark ? AppColors.darkGradient : AppColors.lightGradient,
//           ),
//         ),
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : ListView.builder(
//                 padding: const EdgeInsets.all(16.0),
//                 itemCount: participants.length,
//                 itemBuilder: (context, index) {
//                   final user = participants[index];

//                   return Card(
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: user["profilePic"] != null ? NetworkImage(user["profilePic"]) : const AssetImage("assets/avatar/1.png") as ImageProvider,
//                       ),
//                       title: Text(user["name"] ?? "Unknown", style: GoogleFonts.roboto()),
//                       trailing: isAdmin
//                           ? GestureDetector(
//                               onTap: () {
//                                 removeParticipant(user["userId"]);
//                               },
//                               child: Text(
//                                 'Remove',
//                                 style: GoogleFonts.roboto(fontSize: 14),
//                               ),
//                             )
//                           : null,
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }

class Particiapntgrp extends StatefulWidget {
  final String chatRoomId;
  final ChatRoom chatRoom;

  const Particiapntgrp({
    super.key,
    required this.chatRoomId,
    required this.chatRoom,
  });

  @override
  State<Particiapntgrp> createState() => _ParticiapntgrpState();
}

class _ParticiapntgrpState extends State<Particiapntgrp> {
  List<dynamic> participants = [];
  String? adminId;
  bool isLoading = true;
  String groupName = "";
  String groupImage = "";
  String groupBio = "";
  int memberCount = 0;
  List<Map<String, dynamic>> followers = [];
  List<String> selectedParticipants = [];

  @override
  void initState() {
    super.initState();
    fetchChatRoomDetails();
    _fetchFollowers();
    // Add focus listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = Navigator.of(context);
      navigator.focusNode.addListener(() {
        if (navigator.focusNode.hasFocus) {
          fetchChatRoomDetails();
        }
      });
    });
  }

  Future<void> _fetchFollowers() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      final response = await http.get(
        Uri.parse('${BASE_URL}api/followings'),
        headers: {
          'userid': userId ?? '',
          'token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          followers = List<Map<String, dynamic>>.from(data['result']);
          isLoading = false;
        });
        print("Followers fetched successfully: ${followers.length}");
      }
    } catch (e) {
      print('Error fetching followers: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> addParticipants(String chatRoomId, List<String> participants) async {
    final url = Uri.parse('${BASE_URL}api/add-participants');

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('user_token') ?? '';

    final headers = {
      'Content-Type': 'application/json',
      'userId': userId,
      'token': token,
    };

    final body = json.encode({
      'chatRoomId': chatRoomId,
      'participants': participants,
    });

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print('Participants added successfully!');
      } else {
        print('Failed to add participants: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchChatRoomDetails() async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final String? userId = userProvider.userId;

      final String? token = userProvider.userToken;

      if (userId == null || token == null) {
        throw Exception("User credentials not found.");
      }

      print(userId); // Debug print moved here
      print('##########################################################################################################');
      print(widget.chatRoomId);
      print('********************************************************&&&&&&&&&&&&&');
      final response = await http.get(
        Uri.parse("${BASE_URL}api/get-chatroom-details?chatRoomId=${widget.chatRoomId}"),
        headers: {
          'userId': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // participants = data["chatRoom"]["participants"];
          // adminId = data["chatRoom"]["admin"]; // Store Admin ID
          // isLoading = false;
          // groupName = data["chatRoom"]["groupName"];
          // groupImage = data["chatRoom"]["profileUrl"] ?? "";
          // memberCount = participants.length;
          participants = List.from(data["chatRoom"]["participants"])
            ..sort((a, b) {
              if (a["userId"] == data["chatRoom"]["admin"]) return -1;
              if (b["userId"] == data["chatRoom"]["admin"]) return 1;
              return 0;
            });
          adminId = data["chatRoom"]["admin"];
          isLoading = false;
          groupName = data["chatRoom"]["groupName"];
          groupBio = data["chatRoom"]["bio"] ?? "No Description Available";
          groupImage = data["chatRoom"]["profileUrl"] ?? "";
          // Update this line
          memberCount = participants.where((participant) => participant["status"] == "active").length;
        });
      } else {
        throw Exception("Failed to load chat room details");
      }
    } catch (error) {
      print("Error fetching chat room details: $error");
      setState(() {
        isLoading = false;
      });
    }
    ;
  }

  Future<void> leaveChatroom(String chatRoomId) async {
    final url = Uri.parse("${BASE_URL}api/leave-chatroom");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('user_token') ?? '';
    final headers = {
      'userId': userId,
      'token': token,
      "Content-Type": "application/json"
    };
    final body = jsonEncode({
      "chatRoomId": chatRoomId
    });
    log(body.toString());
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        log(response.body.toString());
        Fluttertoast.showToast(msg: "Group Left Successfully", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.white, textColor: Colors.black, fontSize: 16.0);
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        print("Failed to leave the chatroom. Status code: ${response.statusCode}, Response: ${response.body}");
        Fluttertoast.showToast(msg: "Failed to leave group", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
      }
    } catch (e) {
      print("An error occurred: $e");
      Fluttertoast.showToast(msg: "Error leaving group", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
    }
  }

  void _showDeleteGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Group'),
          content: Text('Are you sure you want to delete this group? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteGroup(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGroup(BuildContext context) async {
    try {
      final url = Uri.parse('${BASE_URL}api/delete-group');
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final String? token = userProvider.userToken;
      final headers = {
        'userid': adminId ?? '',
        'token': token ?? '',
        'Content-Type': 'application/json',
        'Authorization': 'Basic Og=='
      };

      final body = jsonEncode({
        'chatId': widget.chatRoomId
      });

      final response = await http.delete(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          Fluttertoast.showToast(msg: "Group deleted successfully", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.white, textColor: Colors.black, fontSize: 16.0);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => ChatScreen()),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: "Failed to delete group",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: "Error deleting group",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          leading: InkWell(
              onTap: () {
                // Pop first
                Navigator.pop(context);

                // Then push the new screen after a short delay
                if (context.mounted) {
                  Future.microtask(() {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DChatScreen(
                          chatRoom: widget.chatRoom,
                        ),
                      ),
                    );
                  });
                }
              },
              child: Icon(
                Icons.arrow_back_ios_new,
              )),
          actions: (adminId != Provider.of<UserProviderall>(context, listen: false).userId)
              ? []
              : [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditGroupScreen(
                              chatRoomId: widget.chatRoomId,
                              onGroupUpdated: () {
                                setState(() {
                                  fetchChatRoomDetails();
                                });
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Color(0xFFC08EF9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          side: BorderSide(color: Color(0xFF7400A5), width: 2.0),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 4.0.h),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14.0.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteGroupDialog(context);
                    },
                  ),
                ],
          automaticallyImplyLeading: false,
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 50.h,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                      // title: Text(groupName),
                    ),
                    actions: (adminId != Provider.of<UserProviderall>(context, listen: false).userId)
                        ? []
                        : [
                            // Padding(
                            //   padding: const EdgeInsets.only(right: 16.0),
                            //   child: ElevatedButton(
                            //     onPressed: () {
                            //       Navigator.push(
                            //         context,
                            //         MaterialPageRoute(
                            //           builder: (context) => EditGroupScreen(
                            //             chatRoomId: widget.chatRoomId,
                            //             onGroupUpdated: () {
                            //               setState(() {
                            //                 fetchChatRoomDetails();
                            //               });
                            //             },
                            //           ),
                            //         ),
                            //       );
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: Colors.transparent,
                            //       foregroundColor: Color(0xFFC08EF9),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(30.0),
                            //         side: BorderSide(
                            //             color: Color(0xFF7400A5), width: 2.0),
                            //       ),
                            //       elevation: 0,
                            //       padding: EdgeInsets.symmetric(
                            //           horizontal: 24.0.w, vertical: 4.0.h),
                            //     ),
                            //     child: Text(
                            //       'Edit',
                            //       style: TextStyle(
                            //         fontSize: 16.0.sp,
                            //         fontWeight: FontWeight.w500,
                            //         color: Theme.of(context).brightness ==
                            //                 Brightness.dark
                            //             ? Colors.white
                            //             : Colors.black,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                    automaticallyImplyLeading: false,
                  ),
                  // CircleAvatar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35.sp,
                            backgroundColor: Color(0xFF7400A5),
                            backgroundImage: groupImage.isNotEmpty ? NetworkImage(groupImage) : null,
                            child: groupImage.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: SvgPicture.asset(
                                      'assets/icons/group.svg',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : null,
                          ),
                          Text(
                            "${groupName}",
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 24.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Members $memberCount",
                            style: TextStyle(color: Colors.grey, fontSize: 15.sp),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            groupBio,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              if (adminId != Provider.of<UserProviderall>(context, listen: false).userId)
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Color(0xFFC08EF9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30.0),
                                        side: BorderSide(color: Color(0xFF7400A5), width: 2.0),
                                      ),
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 4.0.h),
                                    ),
                                    child: Text(
                                      "Leave",
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.red,
                                      ),
                                    ),
                                    onPressed: () {
                                      leaveChatroom(widget.chatRoomId);
                                    },
                                  ),
                                ),
                              SizedBox(width: 16),
                              if (adminId == Provider.of<UserProviderall>(context, listen: false).userId)
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF7400A5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: Text(
                                      "Add +",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      if (followers.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Center(child: Text('Loading followers list, please wait...'))),
                                        );
                                        return;
                                      }

                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => _BuildParticipantsScreen(
                                              followers: followers,
                                              isLoading: isLoading,
                                              selectedParticipants: selectedParticipants,
                                              onParticipantsSelected: (participants) {
                                                setState(() => selectedParticipants = participants);
                                                //_createGroup();
                                                addParticipants(widget.chatRoomId, selectedParticipants);
                                              },
                                              chatRoomId: widget.chatRoomId,
                                            ),
                                          ));
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Members (${memberCount})",
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Filter participants to only show active ones
                        final activeParticipants = participants.where((participant) => participant["status"] == "active").toList();

                        if (index >= activeParticipants.length) {
                          return null;
                        }

                        final user = activeParticipants[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF7400A5),
                            backgroundImage: user["profilePic"] != null ? NetworkImage(user["profilePic"]) : null,
                            child: user["profilePic"] == null
                                ? Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: SvgPicture.asset(
                                      'assets/icons/group.svg',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : null,
                          ),
                          isThreeLine: true,
                          trailing: user["userId"] != adminId
                              ? ThreeDotsMenuRemove(
                                  chatRoomId: widget.chatRoomId,
                                  participantId: user["userId"],
                                  adminId: adminId ?? '',
                                  onRemoveSuccess: (updatedParticipants) {
                                    setState(() {
                                      participants = updatedParticipants;
                                      memberCount = participants.where((participant) => participant["status"] == "active").length;
                                    });
                                  },
                                )
                              : null,
                          title: Text(user["name"], style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                          subtitle: Text(user["userId"] == adminId ? "Admin" : "Member", style: TextStyle(color: Colors.grey)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(
                                  userId: user["userId"],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: participants.where((participant) => participant["status"] == "active").length,
                    ),
                  )
                ],
              ),
      ),
    );
  }
}

class _BuildParticipantsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> followers;
  final bool isLoading;
  final List<String> selectedParticipants;
  final Function(List<String>) onParticipantsSelected;
  final String chatRoomId;

  const _BuildParticipantsScreen({
    required this.followers,
    required this.isLoading,
    required this.selectedParticipants,
    required this.onParticipantsSelected,
    required this.chatRoomId,
  });

  @override
  __BuildParticipantsScreenState createState() => __BuildParticipantsScreenState();
}

class __BuildParticipantsScreenState extends State<_BuildParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFollowers = [];

  @override
  void initState() {
    super.initState();

    filteredFollowers = widget.followers;
  }

  void _filterFollowers(String query) {
    setState(() {
      filteredFollowers = widget.followers.where((follower) {
        return follower['name'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> addParticipants(String chatRoomId, List<String> participants) async {
    final url = Uri.parse('${BASE_URL}api/add-participants');

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('user_token') ?? '';

    final headers = {
      'Content-Type': 'application/json',
      'userId': userId,
      'token': token,
    };

    final body = json.encode({
      'chatRoomId': chatRoomId,
      'participants': participants,
    });

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print('Participants added successfully!');
        // Navigator.pushReplacementReplacement(context, MaterialPageRoute(builder: (context) => DChatScreen(chatRoom: chatRoomId!)))

        Fluttertoast.showToast(msg: "Participants added successfully!", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.green, textColor: Colors.white, fontSize: 16.0);
        Navigator.pop(context);
      } else {
        print('Failed to add participants: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {},
                  ),
                  Text(
                    'Add Friend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white),
                  onChanged: _filterFollowers,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    suffixIcon: Icon(Icons.search, color: Colors.white),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (widget.isLoading)
                Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: filteredFollowers.length,
                    itemBuilder: (context, index) {
                      final follower = filteredFollowers[index];
                      final isSelected = widget.selectedParticipants.contains(follower['_id']);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              widget.selectedParticipants.remove(follower['_id']);
                            } else {
                              widget.selectedParticipants.add(follower['_id']);
                            }
                          });
                        },
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundImage: follower['profilePic'] != null ? NetworkImage(follower['profilePic']) : null,
                                  backgroundColor: Color(0xFF7400A5),
                                  child: follower['profilePic'] == null ? Text(follower['name'][0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 24)) : null,
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF7400A5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              follower['name'] ?? 'name',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 10),
                child: ElevatedButton(
                  onPressed: () {
                    // if (widget.selectedParticipants.isNotEmpty) {
                    //   widget.onParticipantsSelected(widget.selectedParticipants);
                    // }
                    addParticipants(widget.chatRoomId, widget.selectedParticipants);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7400A5),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Add Friend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThreeDotsMenuRemove extends StatelessWidget {
  final String chatRoomId;
  final String participantId;
  final String adminId;
  final Function? onRemoveSuccess;

  const ThreeDotsMenuRemove({
    Key? key,
    required this.chatRoomId,
    required this.participantId,
    required this.adminId,
    this.onRemoveSuccess,
  }) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _removeParticipant(BuildContext context) async {
    try {
      final url = Uri.parse('https://node-service-preprod.ancoway.ai/api/remove-participant');
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final String? token = userProvider.userToken;
      final headers = {
        'userid': adminId,
        'token': token ?? '', // Use your actual token mechanism
        'Content-Type': 'application/json',
        'Authorization': 'Basic Og=='
      };

      final body = jsonEncode({
        'chatRoomId': chatRoomId,
        'participant': participantId
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _showToast(responseData['message'] ?? "Member removed successfully");

        // Get the updated participants list from the response
        if (responseData['chatRoom'] != null && responseData['chatRoom']['participants'] != null) {
          // Pass the entire participants list back to the parent widget
          if (onRemoveSuccess != null) {
            onRemoveSuccess!(responseData['chatRoom']['participants']);
          }
        }
      } else {
        _showToast("Failed to remove member: ${response.statusCode}");
      }
    } catch (e) {
      _showToast("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.red),
              SizedBox(width: 8),
              Text(
                'Remove Member',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'remove':
            _removeParticipant(context);
            break;
        }
      },
    );
  }
}
