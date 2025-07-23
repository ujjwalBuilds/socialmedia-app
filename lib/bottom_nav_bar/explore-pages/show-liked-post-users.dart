import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/utils/constants.dart';

class ReactionsScreen extends StatefulWidget {
  final String feedId;
  final bool isMessage;

  const ReactionsScreen({
    super.key, 
    required this.feedId,
    this.isMessage = false,
  });

  @override
  State<ReactionsScreen> createState() => _ReactionsScreenState();
}

class _ReactionsScreenState extends State<ReactionsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  Map<String, dynamic> reactionsMap = {};
  bool _isLoading = true;

  final List<Map<String, String>> allReactions = [
    {'type': 'like', 'emoji': '👍', 'label': 'Like'},
    {'type': 'love', 'emoji': '❤️', 'label': 'Love'},
    {'type': 'haha', 'emoji': '😂', 'label': 'Haha'},
    {'type': 'dislike', 'emoji': '👎', 'label': 'Dislike'},
    {'type': 'wow', 'emoji': '😲', 'label': 'Wow'},
    {'type': 'sad', 'emoji': '😢', 'label': 'Sad'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchReactions();
  }

  Future<void> _fetchReactions() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    final response = await http.post(
      Uri.parse("${BASE_URL}api/get-all-reactions"),
      headers: {
        "Content-Type": "application/json",
        "userId": userId ?? "",
        "token": token ?? "",
      },
      body: jsonEncode({
        "entityId": widget.feedId,
        "entityType": widget.isMessage ? "message" : "feed",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        reactionsMap = {
          for (var item in data['reactions'])
            item['reactionType']: item['users']
        };
        _tabController =
            TabController(length: reactionsMap.keys.length + 1, vsync: this);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch reactions")),
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAllUsersWithReactions() {
    List<Map<String, dynamic>> allUsers = [];
    reactionsMap.forEach((reactionType, users) {
      final reactionData = allReactions.firstWhere(
        (element) => element['type'] == reactionType,
        orElse: () => {'emoji': '', 'label': reactionType},
      );

      for (var user in users) {
        allUsers.add({
          ...user,
          'reactionType': reactionType,
          'reactionEmoji': reactionData['emoji'],
        });
      }
    });

    // Remove duplicates based on userId
    allUsers = allUsers.fold([], (List<Map<String, dynamic>> list, user) {
      if (!list.any((u) => u['userId'] == user['userId'])) {
        list.add(user);
      }
      return list;
    });

    return allUsers;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isMessage ? "Message Reactions" : "Post Reactions", 
            style: GoogleFonts.poppins()
          ),
          bottom: _isLoading || reactionsMap.isEmpty || _tabController == null
              ? null
              : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'All'),
                    ...reactionsMap.keys.map((reactionType) {
                      final reactionData = allReactions.firstWhere(
                        (element) => element['type'] == reactionType,
                        orElse: () => {'emoji': '', 'label': reactionType},
                      );
                      return Tab(
                          text:
                              '${reactionData['emoji']} ${reactionData['label']}');
                    }).toList(),
                  ],
                ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : reactionsMap.isEmpty
                ? Center(
                    child: Text("No Reactions Found",
                        style: GoogleFonts.poppins(fontSize: 16.sp)))
                : _tabController == null
                    ? const Center(child: Text("No Reactions Found"))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // All tab
                          ListView.builder(
                            itemCount: _getAllUsersWithReactions().length,
                            itemBuilder: (context, index) {
                              final user = _getAllUsersWithReactions()[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    user['profilePic'] ?? 'assets/images/profile.png'
                                  ),
                                ),
                                title: Text(user['name'] ?? 'Unknown User'),
                                trailing: Text(
                                  user['reactionEmoji'],
                                  style: TextStyle(fontSize: 20),
                                ),
                                onTap: () {
                                  print('Tapped userId: ${user['userId']}');
                                },
                              );
                            },
                          ),
                          // Individual reaction tabs
                          ...reactionsMap.entries.map((entry) {
                            final users = entry.value as List;
                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      user['profilePic'] ?? 'assets/images/profile.png'
                                    ),
                                  ),
                                  title: Text(user['name'] ?? 'Unknown User'),
                                  onTap: () {
                                    print('Tapped userId: ${user['userId']}');
                                  },
                                );
                              },
                            );
                          }).toList(),
                        ],
                      ),
      ),
    );
  }
}
