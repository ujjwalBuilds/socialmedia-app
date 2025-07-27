import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/chatProvider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/see_participants.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/shimmerchatscreen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group_call.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group_call_bottom_sheet.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/services/agora_Call_Service.dart';
import 'package:socialmedia/services/agora_video_Call.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/services/message.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/utils/reaction_constants.dart'
    show ReactionConstants;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socialmedia/bottom_nav_bar/activity/group/editgroupscreen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/rendering.dart';

class DChatScreen extends StatefulWidget {
  ChatRoom chatRoom;

  DChatScreen({required this.chatRoom});

  @override
  DChatScreenState createState() => DChatScreenState();
}

class DChatScreenState extends State<DChatScreen> {
  final TextEditingController _controller = TextEditingController();
  static const _pageSize = 20;
  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 1);
  String? userid;
  late IO.Socket _socket;
  final SocketService _socketService = SocketService();
  Map<String, Participant> participantsMap = {};
  bool isnewconversation = true;
  late UserProviderall userProvider;
  late Future<List<String>> _randomTextFuture;
  bool isNewConversation = true;
  bool _isMessagesLoaded = false;
  Message? _replyingToMessage;
  final GlobalKey<AnimatedListState> _replyPreviewKey = GlobalKey();
  String _receiverid = '';
  String lastSeen = '';
  final Map<String, Message> _allMessagesById = {};

  @override
  void initState() {
    super.initState();
    print(
        '🚀 Initializing DChatScreen for chatRoomId: ${widget.chatRoom.chatRoomId}');
    print('📱 Room type: ${widget.chatRoom.roomType}');
    print(
        '👥 Initial participants count: ${widget.chatRoom.participants.length}');

    // Initialize userProvider first
    userProvider = Provider.of<UserProviderall>(context, listen: false);

    // Refresh group details first if it's a group chat
    if (widget.chatRoom.roomType == 'group') {
      print('🔄 Starting group details refresh...');
      refreshGroupDetails().then((_) {
        print('✅ Group details refresh completed');
        // Initialize other data after refreshing group details
        _initializeBasicData();
      });
    } else {
      // If not a group chat, just initialize basic data
      _initializeBasicData();
    }
  }

  Future<void> _initializeBasicData() async {
    try {
      // Load user data first
      await userProvider.loadUserData();
      log(userProvider.userId!);

      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userid = prefs.getString('user_id');

      if (userid == null) {
        print('Error: User ID is null');
        return;
      }

      // Initialize socket connection
      await _ensureSocketConnection();

      // Initialize chat after socket connection
      await _initializeChat();

      // Initialize participants map only after we have userid
      if (mounted) {
        initParticipantsMap(widget.chatRoom.participants);
      }

      // Initialize paging controller
      _pagingController.addPageRequestListener((pageKey) {
        _fetchPage(pageKey);
      });

      if (mounted) {
        setState(() {
          _randomTextFuture = fetchRandomText();
        });
      }

      // Fetch first page
      await _fetchPage(1);
    } catch (e) {
      print('Initialization error: $e');
      // Handle error appropriately
    }
  }

  void initParticipantsMap(List<Participant> participants) {
    if (userid == null) {
      print('Error: Cannot initialize participants map without user ID');
      return;
    }

    participantsMap.clear();
    for (var participant in participants) {
      if (participant.userId != userid) {
        participantsMap[participant.userId] = participant;
      }
    }
  }

  Future<void> _ensureSocketConnection() async {
    try {
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }
    } catch (e) {
      print('Socket connection error: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      await _socketService.connect();
      print('✅ Socket connected: ${_socketService.isConnected}');

      // Remove any existing receiveMessage listener to avoid duplicates
      // _socketService.socket.off('receiveMessage');

      // Set up the receiveMessage listener with enhanced debugging
      _socketService.socket.on('receiveMessage', (data) {
        print('✅✅✅ Received message via socket: $data');
        try {
          Map<String, dynamic> messageMap;
          if (data is String) {
            messageMap = jsonDecode(data) as Map<String, dynamic>;
          } else if (data is Map) {
            messageMap = Map<String, dynamic>.from(data);
          } else {
            throw Exception('Unexpected data type: ${data.runtimeType}');
          }

          print('Parsed message keys: ${messageMap.keys.toList()}');
          final newMessage = Message.fromJson(messageMap);
          final userProvider =
              Provider.of<UserProviderall>(context, listen: false);
          final currentUserId = userProvider.userId;
          // Only insert into the UI if the message is not from the current user.
          if (newMessage.senderId != currentUserId) {
            if (_pagingController.itemList == null) {
              _pagingController.itemList = [];
            }
            _pagingController.itemList!.insert(0, newMessage);
            _pagingController.notifyListeners();
            print('✅ New message added to list: $newMessage');
          } else {
            print('Message not added since it is from the current user.');
          }
        } catch (e) {
          print('🚨 Error processing socket message: $e');
        }
      });

      // Debug log to confirm room joining
      print('✅ Joining room: ${widget.chatRoom.chatRoomId}');
      _socketService.joinRoom(widget.chatRoom.chatRoomId);
    } catch (e, stackTrace) {
      print('❌ Chat initialization error: $e');
      print('📜 Stack trace: $stackTrace');
    }
  }

  Future<List<String>> fetchRandomText() async {
    //print(widget.chatRoom.participants.first.)
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    String url =
        '${BASE_URL}api/getRandomText?other=${widget.chatRoom.participants.first.userId}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'userid': userProvider.userId!,
        'token': userProvider.userToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String topicText = data['topic'] ?? '';

      // Splitting the text into individual messages
      List<String> messages = topicText.split('\n').map((msg) {
        // Remove leading numbers (e.g., "1. ") and quotation marks
        return msg
            .replaceAll(RegExp(r'^\d+\.\s*'), '')
            .replaceAll('"', '')
            .trim();
      }).toList();

      return messages;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> markMessageAsSeen(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/messages/interact'),
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({"entityId": id, "reactionType": "seen"}),
      );

      if (response.statusCode == 200) {
        print('Message marked as seen');
      } else {
        print('Failed to mark message as seen: ${response.body}');
      }
    } catch (error) {
      print('Error marking message as seen: $error');
    }
  }

  Future<void> initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId =
        prefs.getString('user_id'); // Fetch user ID from SharedPreferences
    print('yelelelelelelellee $userId');

    if (userId == null) {
      debugPrint("User ID not found in SharedPreferences");
      return; // Exit if userId is null
    }

    _socket = IO.io(BASE_URL, <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    _socket.connect();
    print('hogyaaaa');
    _socket.emit('openCall', userId);

    _socket.onConnect((_) {
      debugPrint("Connected to socket server");
    });
  }

  Future<void> fetchUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getString('user_id');
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    log('Fetching page $pageKey with pageSize $_pageSize', name: 'Messages');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        log('Error: User credentials not found', name: 'Messages');
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/get-all-messages'),
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "roomId": widget.chatRoom.chatRoomId,
          "page": pageKey.toString(),
          "limit": _pageSize.toString(),
        }),
      );

      if (response.statusCode == 200) {
        // Log raw response body
        log('📦 Messages Response:', name: 'Messages');
        log(response.body, name: 'Messages');

        final data = json.decode(response.body);

        // Extract and set agoTime for DM chats from the first message
        if (widget.chatRoom.roomType == 'dm' &&
            data['messages'] is List &&
            data['messages'].isNotEmpty) {
          final firstMessage = data['messages'][0];
          final String agoTimeValue = firstMessage['agoTime'] ?? '';

          if (mounted && agoTimeValue.isNotEmpty) {
            setState(() {
              lastSeen = 'last seen $agoTimeValue';
            });
          }
        }

        // Create messages from response
        final List<Message> fetchedMessages = (data['messages'] as List)
            .map((msg) => Message.fromJson(msg))
            .toList();

        log('Fetched ${fetchedMessages.length} messages', name: 'Messages');

        // Update reply relationships for all fetched messages
        _updateReplyRelationships(fetchedMessages);

        // Fetch reactions for each message
        log('Fetching reactions for all messages', name: 'MessagesReactions');

        List<Message> updatedMessages = [];
        for (var message in fetchedMessages) {
          log('Fetching reactions for message: ${message.id}',
              name: 'MessagesReactions');

          // Fetch reactions for the message
          final reactions = await fetchMessageReactions(message.id);

          log('Retrieved ${reactions.length} reactions for message: ${message.id}',
              name: 'MessagesReactions');

          // Create updated message with fetched reactions
          final updatedMessage = message.copyWith(reactions: reactions);
          updatedMessages.add(updatedMessage);
        }

        // Log message data for DM chats
        if (widget.chatRoom.roomType == 'dm') {
          log('📱 Loading DM chat messages:', name: 'Messages');
        }

        if (updatedMessages.isNotEmpty) {
          isnewconversation = false;
          isNewConversation = false;
          markMessageAsSeen(data['messages'][0]['_id']);
          log('Marked message as seen: ${data['messages'][0]['_id']}',
              name: 'Messages');
        }

        setState(() {
          isnewconversation;
        });

        if (pageKey == 1) {
          setState(() {
            _isMessagesLoaded = true;
          });
          log('First page loaded, _isMessagesLoaded set to true',
              name: 'Messages');
        }

        final isLastPage = updatedMessages.length < _pageSize;
        if (isLastPage) {
          log('Appending last page, messages count: ${updatedMessages.length}',
              name: 'Messages');
          _pagingController.appendLastPage(updatedMessages);
        } else {
          log('Appending page $pageKey, messages count: ${updatedMessages.length}',
              name: 'Messages');
          _pagingController.appendPage(updatedMessages, pageKey + 1);
        }
      } else {
        log('Failed to load messages: ${response.statusCode}',
            name: 'Messages');
        _pagingController.error = 'Failed to load messages';
      }
    } catch (error) {
      log('Error in _fetchPage: $error', name: 'Messages');
      _pagingController.error = error;
    }
  }

  Future<void> _sendMessage() async {
    final message = _controller.text;
    if (message.isEmpty || userid == null) return;

    try {
      // Create a temporary message object with current time
      final newMessage = Message(
        id: DateTime.now().toString(), // Temporary ID
        content: message,
        senderId: userid!,
        timestamp: DateTime.now(),
        time: DateFormat('HH:mm').format(DateTime.now()), // Add current time
      );

      // Add message to the list immediately
      setState(() {
        if (_pagingController.itemList == null) {
          _pagingController.itemList = [];
        }
        _pagingController.itemList!.insert(0, newMessage);
      });

      // Clear the input field
      _controller.clear();

      // Send the message through socket with time parameter
      _socketService.sendMessage(
        userid!,
        widget.chatRoom.chatRoomId,
        message,
        DateFormat('HH:mm').format(DateTime.now()), // Add time parameter
        false,
        false,
      );

      setState(() {
        isNewConversation = false;
      });
    } catch (e) {
      print('Error sending message: $e');
      // Optionally remove the message if sending failed
      if (_pagingController.itemList != null) {
        setState(() {
          _pagingController.itemList!.removeAt(0);
        });
      }
    }
  }

  Future<void> _joinCall(String callId, String type, bool fromgroup) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('callToken');
    final channelName = prefs.getString('channelName');
    bool isvideo = type == 'video' ? true : false;

    if (token == null || channelName == null) return;

    _socketService.joinCall(callId, userid!);

    if (fromgroup) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VideoCallScreen(
                    roomId: widget.chatRoom.chatRoomId,
                    participantsMap: participantsMap,
                    currentUserId: userid!,
                    isVideoCall: isvideo,
                    token: token,
                    channel: channelName,
                    callID: callId,
                  )));
      return;
    }

    if (type == 'audio') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgoraCallService(
            channel: channelName,
            token: token,
            callID: callId,
            profile: widget.chatRoom.participants.first.profilePic == null
                ? 'assets/avatar/3.png'
                : widget.chatRoom.participants.first.profilePic!,
            name: widget.chatRoom.participants.first.name!,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgoraVidCall(
              channel: channelName,
              token: token,
              callerName: 'Video Call',
              call_id: callId,
              profile: widget.chatRoom.participants.first.profilePic == null
                  ? 'assets/avatar/3.png'
                  : widget.chatRoom.participants.first.profilePic!,
              name: widget.chatRoom.participants.first.name!),
        ),
      );
    }
  }

  Future<void> startCall(String toUserId, String type, bool fromgrp) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('user_token');

    if (userId == null || token == null) return;

    final response = await http.post(
      Uri.parse('${BASE_URL}api/start-call'),
      headers: {
        'userid': userId,
        'token': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "to": widget.chatRoom.chatRoomId,
        "type": type,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await prefs.setString('channelName', data['call']['channelName']);
      await prefs.setString('callToken', data['token']);
      print('Call started: ${data['message']}');

      _socketService.initiateCall(
          data['call']['_id'], userId, [toUserId], type);
      _joinCall(data['call']['_id'], type, fromgrp);

      // if (type == 'audio') {
      //   Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => AgoraCallService(
      //                 channel: data['call']['channelName'],
      //                 token: data['token'],
      //                 callID: data['call']['_id'],
      //               )));
      // } else {
      //   Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => AgoraVidCall(
      //                 channel: data['call']['channelName'],
      //                 token: data['token'],
      //                 callerName: 'video call',
      //                 call_id: data['call']['_id'],
      //               )));
      // }
    } else {
      print('Failed to start call');
    }
  }

  void showAddFriendsSheet(BuildContext context,
      Map<String, Participant> participantsMap, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: AddFriendsBottomSheet(
          participantsMap: participantsMap,
          onInvite: (userId) async {
            await startCall(widget.chatRoom.chatRoomId, type, true);
            // Handle invite logic here

            print('Inviting user: $userId');
            // You might want to add API call to invite user
          },
        ),
      ),
    );
  }

  void _copyAndPasteText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _controller.text = text; // Automatically set text in the input field
  }

  String truncateName(String name, {int maxLength = 10}) {
    return name.length > maxLength
        ? '${name.substring(0, maxLength)}...'
        : name;
  }

  Future<void> refreshGroupDetails() async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);

      final response = await http.get(
        Uri.parse(
            '${BASE_URL}api/get-chatroom-details?chatRoomId=${widget.chatRoom.chatRoomId}'),
        headers: {
          'UserId': userProvider.userId!,
          'token': userProvider.userToken!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final chatRoomData = data['chatRoom'];
        // print(
        //     '👥 Group participants count: ${(chatRoomData['participants'] as List).length}');
        // print('🏷️ Group name: ${chatRoomData['groupName']}');
        // print('👑 Admin ID: ${chatRoomData['admin']}');
        // print('📅 Created at: ${chatRoomData['createdAt']}');
        // print('🔄 Last updated: ${chatRoomData['updatedAt']}');
        // print('👀 Unseen count: ${chatRoomData['unseenCount']}');

        setState(() {
          widget.chatRoom = ChatRoom(
              id: chatRoomData['_id'],
              chatRoomId: chatRoomData['chatRoomId'],
              participants: (chatRoomData['participants'] as List)
                  .map((p) => Participant.fromJson(p))
                  .toList(),
              roomType: chatRoomData['roomType'],
              groupName: chatRoomData['groupName'],
              profileUrl: chatRoomData['profileUrl'],
              admin: chatRoomData['admin'],
              lastmessage: chatRoomData['lastMessage'] != null
                  ? Lastmessage.fromJson(chatRoomData['lastMessage'])
                  : null,
              createdAt: DateTime.parse(chatRoomData['createdAt']),
              updatedAt: DateTime.parse(chatRoomData['updatedAt']),
              isPart: chatRoomData['isPart'],
              lastseencount: chatRoomData['unseenCount'],
              groupProfile: chatRoomData['profileUrl']);
        });
      } else {
        print(
            '❌ Failed to refresh group details. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error refreshing group details: $error');
    }
  }

  // Add this method to force refresh the screen
  void forceRefresh() async {
    if (mounted) {
      await refreshGroupDetails();
      setState(() {}); // Force rebuild the UI with new data
    }
  }

  void _setReplyingToMessage(Message message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _showReplyOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              100, // Add extra padding
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.reply, color: Color(0xFF7400A5)),
              title: Text('Reply'),
              onTap: () {
                _setReplyingToMessage(message);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReplyMessage() async {
    if (_controller.text.isEmpty || _replyingToMessage == null) return;

    try {
      // Create the message with reply information and current time
      final replyMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _controller.text,
          senderId: userid!,
          timestamp: DateTime.now(),
          replyToMessageId: _replyingToMessage!.id,
          replyToMessage: _replyingToMessage,
          time: DateFormat('HH:mm').format(DateTime.now())); // Add current time

      // Send via socket with time parameter
      _socketService.sendReplyMessage(
        senderId: userid!,
        roomId: widget.chatRoom.chatRoomId,
        content: _controller.text,
        replyToMessageId: _replyingToMessage!.id,
        time: DateFormat('HH:mm').format(DateTime.now()), // Add time parameter
      );

      // Add to UI immediately
      if (mounted) {
        setState(() {
          _pagingController.itemList?.insert(0, replyMessage);
          _replyingToMessage = null;
        });
      }

      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: ${e.toString()}')),
        );
      }
    }
  }

  Message? _findMessageById(String messageId) {
    // First check in our global message map
    if (_allMessagesById.containsKey(messageId)) {
      print('📍 Found replied message in global map: $messageId');
      return _allMessagesById[messageId];
    }

    // Then check in the current page controller items
    if (_pagingController.itemList != null) {
      final message = _pagingController.itemList!.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => Message(
          id: messageId,
          content: "Original message not found",
          senderId: "",
          timestamp: DateTime.now(),
        ),
      );
      print('🔍 Found replied message in current page: ${message.id}');
      return message;
    }

    print('❌ Could not find replied message: $messageId');
    return null;
  }

  void _updateReplyRelationships(List<Message> messages) {
    for (var message in messages) {
      // Add to global message map
      _allMessagesById[message.id] = message;

      // Try to link reply relationships
      if (message.replyToMessageId != null) {
        final replyToMessage = _findMessageById(message.replyToMessageId!);
        if (replyToMessage != null) {
          print('🔗 Linking reply relationship:');
          print('   Message: ${message.id}');
          print('   Replying to: ${replyToMessage.id}');
          print('   Reply content: ${replyToMessage.content}');
          _allMessagesById[message.id] =
              message.copyWith(replyToMessage: replyToMessage);
        }
      }
    }
  }

// Currently sending Base64 String of Raw Image Data , Need to Change it to upload uri
  Future<void> _pickAndSendMedia() async {
    try {
      print('📁 Starting image picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;
        final fileName = file.name;

        print('📄 Selected image details:');
        print('   Path: $filePath');
        print('   Name: $fileName');

        if (filePath == null) {
          print('❌ Error: File path is null');
          return;
        }

        // Create a temporary message object with local file path for preview
        final newMessage = Message(
          id: DateTime.now().toString(),
          content: '',
          senderId: userid!,
          timestamp: DateTime.now(),
          time: DateFormat('HH:mm').format(DateTime.now()),
          media: filePath, // Use local path for immediate preview
          mediaType: MediaType.image,
          mediaName: fileName,
        );

        print('💬 Created temporary message with local file path');

        // Add message to the list immediately for preview
        setState(() {
          if (_pagingController.itemList == null) {
            _pagingController.itemList = [];
          }
          _pagingController.itemList!.insert(0, newMessage);
        });

        try {
          print('🔌 Sending file through socket...');

          // Read and compress the image
          final bytes = await File(filePath).readAsBytes();
          final compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minHeight: 1024, // Max height
            minWidth: 1024, // Max width
            quality: 70, // Compression quality
          );

          final base64File = base64Encode(compressedBytes);

          print('📤 Sending message with compressed image...');
          _socketService.sendMessage(
            userid!,
            widget.chatRoom.chatRoomId,
            '', // Empty content for media messages
            'message',
            false,
            false,
            media: base64File,
            mediaType: 'image',
            mediaName: fileName,
          );

          print('✅ Message sent through socket');

          // Listen for message receipt confirmation
          _socketService.socket.once('messageConfirmation', (data) {
            print('📥 Received message confirmation:');
            print(json.encode(data));

            if (data != null && data['media'] != null) {
              print('🔗 Server media URL: ${data['media']}');

              // Update the message with the server URL
              setState(() {
                final updatedMessage = newMessage.copyWith(
                  media: data['media'],
                  id: data['_id'] ?? data['id'] ?? newMessage.id,
                );
                final index = _pagingController.itemList!
                    .indexWhere((msg) => msg.id == newMessage.id);
                if (index != -1) {
                  _pagingController.itemList![index] = updatedMessage;
                }
              });
            }
          });
        } catch (e, stackTrace) {
          print('❌ Error during socket send: $e');
          print('📜 Stack trace: $stackTrace');

          // Remove the message if sending fails
          setState(() {
            _pagingController.itemList!.removeAt(0);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending image: $e')),
          );
        }

        setState(() {
          isNewConversation = false;
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> addMessageReaction(String messageId, String reactionType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/reaction'),
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "entityId": messageId,
          "reactionType": reactionType,
          "entityType": "message"
        }),
      );

      print('Reaction API Response: ${response.body}');
    } catch (e) {
      print('Error adding reaction: $e');
    }
  }

  Future<List<Reaction>> fetchMessageReactions(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        print('Error: User credentials not found');
        return [];
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/get-all-reactions'),
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({"entityId": messageId, "entityType": "message"}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Reactions API Response: ${response.body}');

        if (data['reactions'] != null) {
          return (data['reactions'] as List)
              .map((reaction) => Reaction.fromJson(reaction))
              .toList();
        }
      } else {
        print('Failed to fetch reactions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching reactions: $e');
    }
    return [];
  }

  void _updateMessageReaction(String messageId, String reactionType) async {
    try {
      // First add the reaction
      await addMessageReaction(messageId, reactionType);

      // Update the message in the UI immediately
      setState(() {
        final messageIndex = _pagingController.itemList
            ?.indexWhere((msg) => msg.id == messageId);

        if (messageIndex != null && messageIndex != -1) {
          final currentMessage = _pagingController.itemList![messageIndex];
          final currentReactions = currentMessage.reactions ?? [];

          // Check if user already reacted
          final existingReactionIndex = currentReactions
              .indexWhere((r) => r.users.any((u) => u.userId == userid));

          List<Reaction> updatedReactions;
          if (existingReactionIndex != -1) {
            // User already reacted, update the existing reaction
            final existingReaction = currentReactions[existingReactionIndex];
            if (existingReaction.type == reactionType) {
              // Remove reaction if same type is selected again
              updatedReactions = List.from(currentReactions)
                ..removeAt(existingReactionIndex);
            } else {
              // Update reaction type
              updatedReactions = List.from(currentReactions)
                ..[existingReactionIndex] = existingReaction.copyWith(
                  type: reactionType,
                );
            }
          } else {
            // Add new reaction
            updatedReactions = List.from(currentReactions)
              ..add(Reaction(
                type: reactionType,
                count: 1,
                users: [ReactionUser(userId: userid!)],
              ));
          }

          final updatedMessage = currentMessage.copyWith(
            reactions: updatedReactions,
            currentUserReaction: reactionType,
          );
          _pagingController.itemList![messageIndex] = updatedMessage;
        }
      });

      // Then fetch updated reactions from server
      final updatedReactions = await fetchMessageReactions(messageId);

      // Update the message with server data
      setState(() {
        final messageIndex = _pagingController.itemList
            ?.indexWhere((msg) => msg.id == messageId);

        if (messageIndex != null && messageIndex != -1) {
          final updatedMessage =
              _pagingController.itemList![messageIndex].copyWith(
            reactions: updatedReactions,
          );
          _pagingController.itemList![messageIndex] = updatedMessage;
        }
      });
    } catch (e) {
      print('Error updating message reaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMessagesLoaded || userid == null) {
      return CompleteChatShimmer();
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.lightText
              : AppColors.darkText,
          title: FittedBox(
            child: GestureDetector(
              onTap: () {
                if (widget.chatRoom.roomType == 'group') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Particiapntgrp(
                        chatRoomId: widget.chatRoom.chatRoomId,
                        chatRoom: widget.chatRoom,
                      ),
                    ),
                  ).then((_) {
                    // Refresh when returning from Particiapntgrp
                    forceRefresh();
                  });
                }
              },
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBarScreen()));
                      },
                      icon: Icon(Icons.arrow_back_ios)),
                  InkWell(
                    onTap: () {
                      print(widget.chatRoom.participants.first.name);
                    },
                    child: GestureDetector(
                        onTap: () {
                          if (widget.chatRoom.roomType == 'group') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditGroupScreen(
                                        chatRoomId: widget.chatRoom.chatRoomId,
                                        onGroupUpdated: forceRefresh)));
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xFF7400A5),
                          backgroundImage: widget.chatRoom.roomType == 'dm'
                              ? widget.chatRoom.participants.first.profilePic !=
                                      null
                                  ? NetworkImage(widget
                                      .chatRoom.participants.first.profilePic!)
                                  : const AssetImage(
                                      'assets/images/profile.png')
                              : widget.chatRoom.groupProfile != null
                                  ? NetworkImage(widget.chatRoom.groupProfile!)
                                  : null,
                          child: widget.chatRoom.roomType != 'dm' &&
                                  widget.chatRoom.groupProfile == null
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
                        ),
                  ),
                  SizedBox(width: 6.w),
                  if (widget.chatRoom.roomType == 'dm')
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserProfileScreen(
                                    userId: widget
                                        .chatRoom.participants.first.userId)));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            truncateName(
                                widget.chatRoom.participants.first.name ?? ""),
                            style: GoogleFonts.roboto(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (lastSeen.isNotEmpty)
                            Text(
                              lastSeen,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color.fromARGB(255, 185, 184, 184),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (widget.chatRoom.roomType == 'group')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truncateName(widget.chatRoom.groupName!),
                          style: TextStyle(
                              fontSize: 28.sp,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        Text(
                          'Group',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color.fromARGB(255, 185, 184, 184)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkText
                : AppColors.lightText,
          ),
          actions: [
            // if (widget.chatRoom.roomType == 'group')
            //   IconButton(
            //     icon: Icon(Icons.more_vert),
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => EditGroupScreen(
            //             chatRoomId: widget.chatRoom.chatRoomId,
            //             onGroupUpdated: forceRefresh,
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // widget.chatRoom.roomType == 'group'
            //     ? SizedBox(width: 0)
            //     : IconButton(
            //         onPressed: () {
            //           widget.chatRoom.roomType == 'group'
            //               ? showAddFriendsSheet(
            //                   context, participantsMap, 'audio')
            //               : startCall(widget.chatRoom.participants.first.userId,
            //                   "audio", false);
            //         },
            //         icon: Icon(Icons.call, color: Color(0xFF7400A5)),
            //       ),
            SizedBox(
              width: 8.w,
            ),
            // widget.chatRoom.roomType == 'group'
            //     ? SizedBox(
            //         width: 0,
            //       )
            //     : IconButton(
            //         onPressed: () {
            //           widget.chatRoom.roomType == 'group'
            //               ? showAddFriendsSheet(
            //                   context, participantsMap, 'video')
            //               : startCall(widget.chatRoom.participants.first.userId,
            //                   "video", false);
            //         },
            //         icon: Icon(Icons.video_call, color: Color(0xFF7400A5))),
            SizedBox(
              width: 8.w,
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PagedListView<int, Message>(
                  pagingController: _pagingController,
                  reverse: true,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                      itemBuilder: (context, message, index) {
                    final isSender = message.senderId == userid;
                    // Find the replied message if this message is a reply
                    Message? repliedMessage;
                    if (message.replyToMessageId != null) {
                      repliedMessage =
                          _findMessageById(message.replyToMessageId!);
                      print(' Processing message ${message.id}:');
                      print(
                          '  ↪️ Is Reply: ${message.replyToMessageId != null}');
                      print('  📝 Content: ${message.content}');
                      print('  🔍 Reply To ID: ${message.replyToMessageId}');
                      print(
                          '  📨 Found Reply Message: ${repliedMessage != null}');
                      if (repliedMessage != null) {
                        print('  💬 Reply Content: ${repliedMessage.content}');
                      }
                    }

                    return Builder(
                      builder: (context) => InkWell(
                        onLongPress: () {
                          // Get the position of the message bubble
                          final RenderBox? renderBox =
                              context.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            final position =
                                renderBox.localToGlobal(Offset.zero);
                            final size = renderBox.size;

                            showDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (context) => ReactionPopupModal(
                                onReactionSelected: (reactionType) {
                                  _updateMessageReaction(
                                      message.id, reactionType);
                                },
                                currentReaction: message.currentUserReaction,
                                isSender: isSender,
                                position: position,
                                messageSize: size,
                              ),
                            );
                          }
                        },
                        child: MessageBubble(
                          message:
                              message.copyWith(replyToMessage: repliedMessage),
                          isSender: isSender,
                          participantsMap: participantsMap,
                          currentUserId: userid!,
                          reactions: message.reactions ?? [],
                          onReactionSelected: (messageId, reactionType) {
                            _updateMessageReaction(messageId, reactionType);
                          },
                          onReply: (message) {
                            _setReplyingToMessage(message);
                          },
                        ),
                      ),
                    );
                  }, noItemsFoundIndicatorBuilder: (context) {
                    return Center(
                      child: Text(
                        'No Messages Yet. Start The Conversation',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (widget.chatRoom.roomType == 'group' &&
                  !widget.chatRoom.isPart)
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Center(
                    child: Text(
                      'You have left this group',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (_replyingToMessage != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade400,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Replying to ${participantsMap[_replyingToMessage!.senderId]?.name ?? 'User'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF7400A5),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _replyingToMessage!.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _replyingToMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isNewConversation
                        ? FutureBuilder<List<String>>(
                            future: _randomTextFuture,
                            builder: (context, snapshot) {
                              if (!isNewConversation)
                                return const SizedBox.shrink();

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: 80,
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.purple[300]!,
                                    highlightColor: Colors.purple[100]!,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 3,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Container(
                                            width: 250,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return SizedBox(
                                  height: 80,
                                  child: Center(
                                      child: Text('Error: ${snapshot.error}')),
                                );
                              } else {
                                final List<String> suggestions =
                                    snapshot.data ?? [];
                                if (suggestions.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 4.0),
                                        child: Text(
                                          'BondChat Suggestions',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.darkText
                                                    : AppColors.lightText,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 90,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: suggestions.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: GestureDetector(
                                                onTap: () => _copyAndPasteText(
                                                    suggestions[index]),
                                                child: Container(
                                                  width: 250,
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF7400A5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Icon(Icons.message,
                                                          color: Colors.white),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          suggestions[index],
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          )
                        : const SizedBox.shrink(),
                    Row(
                      children: [
                        // IconButton(
                        //   icon: Icon(Icons.photo_library,
                        //       color: Color(0xFF7400A5)),
                        //   onPressed: _pickAndSendMedia,
                        // ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: _controller,
                                  enabled:
                                      widget.chatRoom.roomType != 'group' ||
                                          widget.chatRoom.isPart,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        widget.chatRoom.roomType == 'group' &&
                                                !widget.chatRoom.isPart
                                            ? 'You have left this group'
                                            : 'Type A Message...',
                                    hintStyle: GoogleFonts.poppins(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white60
                                            : AppColors.lightText),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        if (widget.chatRoom.roomType != 'group' ||
                            widget.chatRoom.isPart)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF7400A5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.send, color: Colors.white),
                              onPressed: () {
                                if (_replyingToMessage != null) {
                                  _sendReplyMessage();
                                } else {
                                  _sendMessage();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers and other resources
    _pagingController.dispose();
    _controller.dispose();

    // Clear the message handler to avoid memory leaks
    //  _socketService.onMessageReceived = null;

    // Emit the "leave" event when leaving the page
    if (_socketService.isConnected) {
      _socketService.socket.emit('leave', widget.chatRoom.chatRoomId);
      print('✅ Emitted leave event for room: ${widget.chatRoom.chatRoomId}');
    }

    super.dispose();
  }
}

class ReactionPopupModal extends StatelessWidget {
  final Function(String) onReactionSelected;
  final String? currentReaction;
  final bool isSender;
  final Offset position;
  final Size messageSize;

  const ReactionPopupModal({
    Key? key,
    required this.onReactionSelected,
    this.currentReaction,
    required this.isSender,
    required this.position,
    required this.messageSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the position based on screen size and message position
    final screenSize = MediaQuery.of(context).size;
    final popupWidth = 200.0;
    final popupHeight = 80.0;

    double left;
    double top;

    // Position horizontally
    if (isSender) {
      left = position.dx - popupWidth + messageSize.width;
    } else {
      left = position.dx;
    }

    // Ensure the popup stays within screen bounds
    if (left + popupWidth > screenSize.width) {
      left = screenSize.width - popupWidth;
    }
    if (left < 0) {
      left = 0;
    }

    // Position vertically
    top = position.dy - popupHeight - 10;
    if (top < 0) {
      top = position.dy + messageSize.height + 10;
    }

    return Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
        // Reaction popup
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: popupWidth,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReactionConstants.availableReactionTypes
                    .map((reactionType) {
                  final emoji =
                      ReactionConstants.reactionTypeToEmoji[reactionType]!;
                  final isSelected = currentReaction == reactionType;

                  return GestureDetector(
                    onTap: () {
                      onReactionSelected(reactionType);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.purple.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
