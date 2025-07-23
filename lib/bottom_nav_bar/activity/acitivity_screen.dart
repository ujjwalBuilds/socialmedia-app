import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/chatProvider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/detailed_chat_page.dart';
import 'package:socialmedia/bottom_nav_bar/activity/find_following_start_chat.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/creategroupscreen.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/explore_screen.dart';
import 'package:socialmedia/community/community.dart';
import 'package:socialmedia/community/communityListView.dart';
import 'package:socialmedia/community/communityProvider.dart';
import 'package:socialmedia/community/suggestedCommunities.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/services/message.dart';
import 'package:socialmedia/users/listtype_shimmer.dart';
import 'package:socialmedia/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChatRoom> chatRooms = [];
  List<ChatRoom> filteredChatRooms = [];
  bool isLoading = true;
  late TextEditingController _messageController;
  late String _userId;
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);

    // Initialize provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.fetchChatRooms();
      final userId = Provider.of<UserProviderall>(context, listen: false).userId;
      Provider.of<CommunityProvider>(context, listen: false).fetchUserCommunities(userId!);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    // Refresh data from provider instead of local method
    Provider.of<ChatProvider>(context, listen: false).fetchChatRooms();
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  String getLastMessageText(String? lastMessage) {
    if (lastMessage != null) {
      try {
        final decoded = json.decode(lastMessage);
        if (decoded is Map || decoded['data'] is Map || decoded['data']['media'] != null) {
          return "shared a post";
        }
      } catch (e) {
        // Handle parsing error (if any)
      }
      return lastMessage;
    }
    return "Tap To Start Chat";
  }

  void _onSearchChanged() {
    final searchQuery = _searchController.text.toLowerCase().trim();

    setState(() {
      _isSearching = searchQuery.isNotEmpty;
    });
    Provider.of<ChatProvider>(context, listen: false).filterChatRooms(searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (context, chatProvider, child) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            leading: InkWell(
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
              },
              child: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black,
              ),
            ),
            title: Text(
              'Activity',
              style: GoogleFonts.roboto(
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateGroupFlow())).then((_) async {
                        // Reset and refresh data when returning from create group flow
                        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                        chatProvider.reset();
                        await chatProvider.fetchChatRooms();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: Color(0xFF7400A5),
                          ),
                          borderRadius: BorderRadius.circular(50.sp)),
                      child: Text(
                        'Create Group',
                        style: GoogleFonts.roboto(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 6.w,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FollowingsScreen())).then((_) {
                        // Refresh data when returning from followings screen
                        Provider.of<ChatProvider>(context, listen: false).fetchChatRooms();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5),
                      decoration: BoxDecoration(color: Color(0xFF7400A5), borderRadius: BorderRadius.circular(50.sp)),
                      child: Text(
                        'Add +',
                        style: GoogleFonts.roboto(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                ],
              )
            ],
          ),
          body: SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            enablePullUp: true,
            header: CustomHeader(
              builder: (context, mode) {
                Widget body;
                if (mode == RefreshStatus.idle) {
                  body = CupertinoActivityIndicator(radius: 14);
                } else if (mode == RefreshStatus.refreshing) {
                  body = CupertinoActivityIndicator(
                    radius: 14,
                  );
                } else if (mode == RefreshStatus.canRefresh) {
                  body = CupertinoActivityIndicator(radius: 14);
                } else {
                  body = CupertinoActivityIndicator(radius: 14);
                }
                return Container(
                  height: 40.0,
                  child: Center(child: body),
                );
              },
            ),
            child: Column(
              children: [
                const Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'Suggested Communities',
                      //   style: GoogleFonts.roboto(
                      //     color: Theme.of(context).brightness == Brightness.dark
                      //         ? Colors.grey[400]
                      //         : Colors.grey[800],
                      //     fontSize: 16,
                      //   ),
                      // ),
                      // SizedBox(height: 12),
                      SuggestedCommunitiesWidget(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController, // Use search controller
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[900]),
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[900]),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged(); // Reset the filtered list
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[400],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.roboto(),
                  tabs: [
                    FittedBox(
                      child: Tab(
                        child: Text('Chats (${chatProvider.getDMCount()})'),
                      ),
                    ),
                    FittedBox(
                      child: Tab(
                        child: Text('My Groups (${chatProvider.getGroupCount()})'),
                      ),
                    ),
                    Consumer<CommunityProvider>(
                      builder: (context, communityProvider, _) {
                        return FittedBox(
                          child: Tab(
                            child: Text(
                                //'Communities (${communityProvider.communityCount})'),
'Communities (${communityProvider.communityCount})'),
                          ),
                        );
                      },
                    ),
                  ],
                  labelColor: Color(0xFF7400A5),
                  unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  indicatorColor: Color(0xFF7400A5),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChatList(isDM: true, chatProvider: chatProvider),
                      _buildChatList(isDM: false, chatProvider: chatProvider),
                      CommunitiesListView(),
                      // Center(child: Center(child: Text('Coming Soon'),),)
                      //Center(child: SuggestedCommunitiesWidget()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildChatList({required bool isDM, required ChatProvider chatProvider}) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final rooms = _isSearching ? provider.filteredChatRooms : provider.chatRooms;
        final filteredRooms = rooms.where((room) => isDM ? room.roomType == 'dm' : room.roomType == 'group').toList();

        if (provider.isLoading) {
          return Center(
            child: LoadingAnimationWidget.twistingDots(
                leftDotColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                rightDotColor: Color(0xFF7400A5),
                size: 20),
          );
        }

        if (filteredRooms.isEmpty) {
          return Center(
              child: _isSearching
                  ? Text(
                      'No matching results',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                      ),
                    )
                  : Text(
                      isDM ? 'No chats found' : 'No groups found',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                      ),
                    ));
        }

        return ListView.builder(
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            String displayText = getLastMessageText(room.lastmessage?.content);

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DChatScreen(chatRoom: room),
                  ),
                ).then((_) {
                  // Refresh data when returning from chat screen
                  Provider.of<ChatProvider>(context, listen: false).fetchChatRooms();
                });
              },
              onLongPress: isDM
                  ? () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext bc) {
                          return SafeArea(
                            child: Wrap(
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text(
                                    'Delete Chat',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    try {
                                      await provider.deleteChat(room.chatRoomId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Chat deleted successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete chat'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF7400A5),
                  backgroundImage: room.roomType == 'dm'
                      ? room.participants.first.profilePic != null
                          ? NetworkImage(room.participants.first.profilePic!)
                          : null
                      : room.groupProfile != null
                          ? NetworkImage(room.groupProfile!)
                          : null,
                  child: (room.roomType == 'dm' && room.participants.first.profilePic == null) || (room.roomType != 'dm' && room.groupProfile == null)
                      ? SvgPicture.asset(
                          'assets/icons/group.svg',
                          width: 25.w,
                          height: 25.w,
                        )
                      : null,
                ),
                title: Text(
                  isDM ? room.participants.first.name ?? 'Anonymous' : room.groupName ?? 'Unnamed Group',
                  style: GoogleFonts.roboto(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  displayText,
                  style: GoogleFonts.roboto(color: Colors.grey),
                ),
                trailing: room.lastseencount != null && room.lastseencount != 0
                    ? Container(
                        height: 22,
                        width: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7400A5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${room.lastseencount}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            );
          },
        );
      },
    );
  }
}

//class for participants and chat room

class ChatRoom {
  final String id;
  final String chatRoomId;
  final List<Participant> participants;
  final Lastmessage? lastmessage;
  final String roomType;
  final String? groupName;
  final String? profileUrl;
  final String? admin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPart;
  final int? lastseencount;
  final String? groupProfile;

  ChatRoom(
      {required this.id,
      required this.chatRoomId,
      required this.participants,
      required this.roomType,
      this.groupName,
      this.profileUrl,
      this.admin,
      this.lastmessage,
      required this.createdAt,
      required this.updatedAt,
      required this.isPart,
      this.lastseencount,
      required this.groupProfile});

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
        id: json['_id'],
        chatRoomId: json['chatRoomId'],
        participants: (json['participants'] as List).map((p) => Participant.fromJson(p)).toList(),
        roomType: json['roomType'],
        groupName: json['groupName'] ?? '',
        profileUrl: json['profileUrl'] ?? '',
        admin: json['admin'],
        lastmessage: json['lastMessage'] != null ? Lastmessage.fromJson(json['lastMessage']) : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        isPart: json['isPart'] ?? true,
        lastseencount: json['unseenCount'],
        groupProfile: json['profileUrl']);
  }
}

class Participant {
  final String userId;
  final String? name;
  final String? profilePic;

  Participant({
    required this.userId,
    this.name,
    this.profilePic,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'],
      name: json['name'],
      profilePic: json['profilePic'],
    );
  }
}

class Lastmessage {
  final String content;
  Lastmessage({required this.content});

  factory Lastmessage.fromJson(Map<String, dynamic> json) {
    return Lastmessage(content: json['content'] ?? 'Start Message');
  }
}
