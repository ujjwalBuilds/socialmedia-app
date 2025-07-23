import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/searched_userprofile.dart' show UserProfileScreen;
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/utils/storyAvatar.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:story_view/story_view.dart';

class StoryViewPage extends StatefulWidget {
  final List<Story_Item> stories;

  const StoryViewPage({required this.stories});

  @override
  _StoryViewPageState createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> {
  final StoryController controller = StoryController();
  List<StoryItem> storyItems = [];
  final TextEditingController messageController = TextEditingController();
  bool isTyping = false;
  int currentStoryIndex = 0; 
  bool isSendingMessage = false; // Track if the user is typing

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _sendMessage() async {
    print("Attempting to send message..."); // Debug print

    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getString('user_id');

    if (senderId == null) {
      print("Sender ID not found");
      return;
    }

    String message = messageController.text.trim();
    if (message.isEmpty) {
      print("Message is empty");
      return;
    }

    final story = widget.stories.first;

    // final entityJson = {
    //   "_id": story.storyid,
    //   "author": story.authorId,
    //   "createdAt": story.createdAt,
    //   "url": story.imageUrl,
    //   "ago_time": story.ago,
    // };
    final entityJson = {
      "entityId": story.storyid,
      "entity": {
        "_id": story.storyid,
        "author": story.authorId,
        "createdAt": story.createdAt,
        "url": story.imageUrl,
        "storyUrl": story.imageUrl,
        "ago_time": story.ago,
      },
      "content": message,
      "isBot": false
    };

    print("Fetching chat room ID...");
    String? chatRoomId = await _getChatRoomId(story.authorId);

    if (chatRoomId == null) {
      print("Chat room not found for author: ${story.authorId}");
      return;
    }

    // final messageJson = {"senderId": senderId, "content": message, "entityId": story.storyid, "media": null, "entity": entityJson, "isBot": false};

    final messageJson = {
      "senderId": senderId,
      "content": message,
      "entityId": chatRoomId, // Use chatRoomId instead of story.storyid
      "media": null, // Don't set media here for story replies
      "entity": entityJson, // Pass the object directly, not JSON encoded
      "isBot": false
    };

    print('ChatRoom ID: $chatRoomId');
    print('Sending message: $messageJson');

    SocketService().sendMessage(senderId, chatRoomId, message, json.encode(entityJson), false, false);

    messageController.clear();
    _resumeStory();
  }

  Future<String?> _getChatRoomId(String authorId) async {
    try {
      print('Fetching chat rooms...');

      // Retrieve user token & ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final token = prefs.getString('user_token') ?? '';

      if (userId.isEmpty || token.isEmpty) {
        print("Error: Missing user ID or token.");
        return null;
      }

      // Set headers
      final headers = {
        'Content-Type': 'application/json',
        'userid': userId,
        'token': token,
      };

      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> chatRooms = data['chatRooms'];

        // Find the chat room where the authorId matches a participant
        for (var room in chatRooms) {
          for (var participant in room['participants']) {
            if (participant['userId'] == authorId) {
              print("Found chat room ID: ${room['chatRoomId']}");
              return room['chatRoomId']; // Return the matching chat room ID
            }
          }
        }

        print("No matching chat room found for author: $authorId");
      } else {
        print("Failed to fetch chat rooms: ${response.body}");
      }
    } catch (e) {
      print("Error fetching chat rooms: $e");
    }

    return null; // Return null if no matching chat room is found
  }

  void _loadStories() {
    for (var story in widget.stories) {
      storyItems.add(
        StoryItem.pageImage(
          url: story.imageUrl,
          controller: controller,
          duration: const Duration(seconds: 5),
          //  imageFit: BoxFit.contain,
        ),
      );
    }
  }

  Future<void> _saveStoryInteraction(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      print('Saving interaction for storyId: $storyId');
      final headers = {
        'Content-Type': 'application/json',
        'token': token,
        'userid': userId,
      };
      final body = json.encode({'storyId': storyId});

      final response = await http.post(
        Uri.parse('${BASE_URL}api/save-interaction'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print('cxxxxxxxxxxxx');
        print('${widget.stories.first.profilepic}');
        print("Interaction saved for storyId: $storyId");
      } else {
        print("Failed to save interaction: ${response.body}");
      }
    } catch (e) {
      print("Error saving interaction: $e");
    }
  }

  void _pauseStory() {
    controller.pause();
    setState(() {
      isTyping = true;
    });
  }

  void _resumeStory() {
    controller.play();
    setState(() {
      isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.black,
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
              child: StoryView(
                storyItems: storyItems,
                controller: controller,
                onStoryShow: (story, index) {
                  if (index != -1) {
                    final storyId = widget.stories[index].storyid;
                    _saveStoryInteraction(storyId);
                  }
                },
                onComplete: () => Navigator.pop(context),
                onVerticalSwipeComplete: (direction) {
                  if (direction == Direction.down) {
                    Navigator.pop(context);
                  }
                },
                progressPosition: ProgressPosition.top,
              ),
            ),
            // Custom header
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                                  userId: widget.stories.first.authorId,
                                )));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(widget.stories.first.profilepic),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.stories.first.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${widget.stories.first.ago.toString()}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Message input field
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          style: const TextStyle(color: Colors.white),
                          onTap: _pauseStory, // Pause story when typing starts
                          onSubmitted: (value) {
                            // Resume the story after the user submits the message
                            _resumeStory();
                          },
                          decoration: InputDecoration(
                            hintText: "Type Your Message Here...",
                            hintStyle: GoogleFonts.roboto(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[900],
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (isSendingMessage) return;
                          if (messageController.text.trim().isEmpty) {
                            print("Cannot send an empty message");
                            return;
                          }
                          _sendMessage().then((_) {
                            isSendingMessage = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF7400A5),
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    messageController.dispose();
    super.dispose();
  }
}
