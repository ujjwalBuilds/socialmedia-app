import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/shimmerchatscreen.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';

import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/services/voice_settings.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:location/location.dart';

class UserRecommendation {
  final String id;
  final String name;
  final String nickName;
  final List<String> interests;
  final int matchingInterestsCount;
  final bool hasMessageInterest;

  UserRecommendation({
    required this.id,
    required this.name,
    required this.nickName,
    required this.interests,
    required this.matchingInterestsCount,
    required this.hasMessageInterest,
  });

  factory UserRecommendation.fromJson(Map<String, dynamic> json) {
    return UserRecommendation(
      id: json['_id'],
      name: json['name'],
      nickName: json['nickName'],
      interests: List<String>.from(json['interests'] ?? []),
      matchingInterestsCount: json['matchingInterestsCount'] ?? 0,
      hasMessageInterest: json['hasMessageInterest'] ?? false,
    );
  }
}

class ChatMessage {
  final String id;
  final dynamic content;
  final String senderId;
  final DateTime createdAt;
  final String? media;
  final String entity;
  final bool isBot;
  final List<UserRecommendation>? userRecommendations;
  final bool isTypingIndicator;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
    this.media,
    required this.entity,
    this.isBot = false,
    this.userRecommendations,
    this.isTypingIndicator = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    dynamic messageContent = json['content'];
    List<UserRecommendation>? users;

    // Check if content is a map with 'users' array
    if (messageContent is Map<String, dynamic> && messageContent.containsKey('users') && messageContent['users'] is List) {
      users = (messageContent['users'] as List).map((user) => UserRecommendation.fromJson(user)).toList();

      // Extract just the text message part
      messageContent = messageContent['message'] ?? '';
    }

    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? DateTime.now().toString(),
      content: messageContent,
      senderId: json['senderId'],
      createdAt: json['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000) : DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      media: json['media'],
      entity: json['entity'] ?? '',
      isBot: json['isBot'] ?? false,
      userRecommendations: users,
      isTypingIndicator: json['isTypingIndicator'] ?? false,
    );
  }
}

class ancoChatScreen extends StatefulWidget {
  const ancoChatScreen({Key? key}) : super(key: key);

  @override
  _ancoChatScreenState createState() => _ancoChatScreenState();
}

class _ancoChatScreenState extends State<ancoChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SocketService _socketService = SocketService();
  final _pagingController = PagingController<int, ChatMessage>(firstPageKey: 1);
  static const _pageSize = 20;

  Location location = Location();

  String? _currentUserId;
  String? _chatRoomId;
  String? _token;
  bool _isLoading = true;
  bool _isSpeakerOn = true;
  bool _isBotTyping = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedVoice = 'male';
  String _botName = 'Michael';
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;
  String _locationMessage = 'Location not fetched yet';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndFetchLocation();
    _loadVoiceSettings();
    _initializeChat();
  }

  Future<void> _checkPermissionsAndFetchLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        setState(() {
          _locationMessage = 'Location service is disabled.';
        });
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          _locationMessage = 'Location permission denied';
        });
        return;
      }
    }

    _locationData = await location.getLocation();
    print("LOcation  $_locationData");
    setState(() {
      _locationMessage = 'Latitude: ${_locationData!.latitude}, Longitude: ${_locationData!.longitude}';
    });
  }

  Future<void> _loadVoiceSettings() async {
    final voice = await VoiceSettings.getSelectedVoice();
    setState(() {
      _selectedVoice = voice;
      _botName = VoiceSettings.getVoiceName(voice);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      print('Fetching page $pageKey for room $_chatRoomId');

      if (_chatRoomId == null) {
        print('Chat room ID is null');
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/get-all-messages'),
        headers: {
          'userid': _currentUserId!,
          'token': _token!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'roomId': _chatRoomId,
          'page': pageKey.toString(),
          'limit': _pageSize.toString(),
        }),
      );

      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> messagesList = responseData['messages'];
        final messages = messagesList.map((msg) => ChatMessage.fromJson(msg)).toList();

        final isLastPage = responseData['currentPage'] >= responseData['totalPages'];

        if (isLastPage) {
          _pagingController.appendLastPage(messages);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(messages, nextPageKey);
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching messages: $error');
      _pagingController.error = error;
    }
  }

  Future<void> _initializeChat() async {
    try {
      print('Initializing chat...');
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('user_token');
      _currentUserId = prefs.getString('user_id');

      print('Token: $_token');
      print('User ID: $_currentUserId');

      if (_token == null || _currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Center(child: Text('Authentication required'))),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/start-message'),
        headers: {
          'userid': _currentUserId!,
          'token': _token!,
          'Content-Type': 'application/json',
        },
        /*DEV ancoCHAT ID */
        //  body: jsonEncode({'userId2': '67d3bf8914c75ee094e30bfa'}),
        /*PREPROD ancoCHAT ID */
        body: jsonEncode({
          'userId2': '67f4ecba7f663162b8466076'
        }),
      );

      print('Start message response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _chatRoomId = responseData['chatRoom']['chatRoomId'];
        });

        // Initialize paging controller after getting chat room ID
        _pagingController.addPageRequestListener((pageKey) {
          _fetchPage(pageKey);
        });

        await _socketService.connect();
        _socketService.joinRoom(_chatRoomId!);

        // Trigger initial load
        _fetchPage(1);

        _socketService.onMessageReceived = (message) {
          final newMessage = ChatMessage.fromJson(message);

          print('Processing new message: $newMessage');

          if (!mounted) return; // Check if widget is still mounted

          if (_pagingController.itemList == null) {
            _pagingController.itemList = [];
          }

          // Only remove typing indicator if this is a bot response
          if (message['isBot'] == true) {
            if (!mounted) return; // Check if widget is still mounted
            setState(() {
              _isBotTyping = false;
              _pagingController.itemList!.removeWhere((msg) => msg.id == 'typing_indicator');
              _pagingController.notifyListeners();
            });
          }

          log('New message received: ${newMessage.id}', name: 'ancoChatScreen');
          // log('New message received: ${msg.id}');

          // Check if message already exists in the list
          final messageExists = _pagingController.itemList!.any((msg) => msg.id == newMessage.id);

          if (!messageExists) {
            if (!mounted) return; // Check if widget is still mounted
            setState(() {
              _pagingController.itemList!.insert(0, newMessage);
              _pagingController.notifyListeners();
            });

            if (_isSpeakerOn && message['isBot'] == true && message['media'] != null) {
              print("🎵 Polly audio detected, playing...");
              Future.microtask(() async {
                if (!mounted) return; // Check if widget is still mounted
                await _playPollyAudio(message['media']);
              });
            }
          } else {
            print('Message already exists in the list, skipping...');
          }
        };
      } else {
        print('Failed to start chat: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Center(child: Text('Failed to start chat'))),
        );
      }
    } catch (e) {
      print('Error initializing chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text('An error occurred'))),
      );
    }
  }

  Future<void> _playPollyAudio(String base64Audio) async {
    try {
      print("🎵 Starting audio playback process...");

      // Decode base64 to binary data
      Uint8List audioBytes = base64Decode(base64Audio);
      print("🎵 Base64 decoded successfully, audio size: ${audioBytes.length} bytes");

      // Get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String filePath = '${tempDir.path}/polly_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // Save audio file
      File audioFile = File(filePath);
      await audioFile.writeAsBytes(audioBytes);
      print("🎵 Audio file saved to: $filePath");

      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Set the audio source and play
      await _audioPlayer.setFilePath(filePath);
      print("🎵 Audio source set successfully");

      // Set the volume based on speaker state
      await _audioPlayer.setVolume(_isSpeakerOn ? 1.0 : 0.0);
      print("🎵 Volume set to: ${_isSpeakerOn ? 1.0 : 0.0}");

      // Add error listener
      _audioPlayer.playbackEventStream.listen(
        (event) {
          print("🎵 Playback event: $event");
        },
        onError: (Object e, StackTrace st) {
          print("⚠ Audio playback error: $e");
        },
      );

      // Play the audio
      await _audioPlayer.play();
      print("🎵 Audio playback started");

      // Clean up the file after playback
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          print("🎵 Audio playback completed, cleaning up file");
          audioFile.delete().catchError((error) {
            print("⚠ Error deleting audio file: $error");
          });
        }
      });
    } catch (e) {
      print("⚠ Error in _playPollyAudio: $e");
    }
  }

  void _toggleVoice(String newVoice) async {
    await VoiceSettings.setSelectedVoice(newVoice);
    setState(() {
      _selectedVoice = newVoice;
      _botName = VoiceSettings.getVoiceName(newVoice);
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _chatRoomId != null) {
      // Create a temporary message for UI preview
      final tempMessage = ChatMessage(
        id: DateTime.now().toString(),
        content: message,
        senderId: _currentUserId!,
        createdAt: DateTime.now(),
        entity: '',
      );

      // Add the temporary message to the UI
      setState(() {
        if (_pagingController.itemList == null) {
          _pagingController.itemList = [];
        }
        // _pagingController.itemList!.insert(0, tempMessage);
        _pagingController.notifyListeners();
      });

      // Set bot typing indicator
      setState(() {
        _isBotTyping = true;
        // Remove any existing typing indicator first
        _pagingController.itemList!.removeWhere((msg) => msg.id == 'typing_indicator');
        // Add new typing indicator
        _pagingController.itemList!.insert(
            0,
            ChatMessage(
              id: 'typing_indicator',
              content: '',
              senderId: 'bot',
              createdAt: DateTime.now(),
              entity: '',
              isTypingIndicator: true,
            ));
        _pagingController.notifyListeners();
      });
      final latitude = _locationData?.latitude;
      final longitude = _locationData?.longitude;
      print("latittude $latitude");
      // Send the message through socket
      _socketService.sendMessage(
        _currentUserId!,
        _chatRoomId!,
        message,
        '',
        true,
        _isSpeakerOn,
        voice: _selectedVoice,
        latitude: latitude,
        longitude: longitude,
      );

      if (_isListening) {
        _speech.stop();
        setState(() => _isListening = false);
      }

      _messageController.clear();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("🎤 Speech Status: $status");
      },
      onError: (errorNotification) {
        print("Speech Error: $errorNotification");
      },
    );

    if (available) {
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          if (!_isListening) return;

          setState(() {
            _messageController.text = result.recognizedWords;
          });

          // Send message **only when speech recognition is complete**
          if (result.finalResult) {
            _sendMessage();
            _messageController.clear();
            setState(() => _isListening = false);
          }
        },
      );
    } else {
      print("Speech Recognition is not available.");
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BottomNavBarScreen()));
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            )),
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Text(_botName, style: GoogleFonts.poppins(color: Colors.white)),
            SizedBox(
              width: 10.w,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF7400A5),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  'Basic',
                  style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.white),
                ),
              ),
            )
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _selectedVoice == 'male' ? Icons.man : Icons.woman,
              color: const Color(0xFF7400A5),
            ),
            onSelected: (String newVoice) {
              setState(() {
                _selectedVoice = newVoice;
              });
              _toggleVoice(newVoice);
            },
            itemBuilder: (BuildContext context) => [
              // Male Voices Header
              const PopupMenuItem(
                enabled: false,
                child: Text('Male Voices', style: TextStyle(color: Colors.grey)),
              ),
              // Michael (selected)
              PopupMenuItem(
                value: 'male',
                child: Row(
                  children: [
                    const Icon(Icons.man, color: Color(0xFF7400A5)),
                    const SizedBox(width: 8),
                    const Text('Michael'),
                    const Spacer(),
                    if (_selectedVoice == 'male') const Icon(Icons.check, color: Colors.grey),
                  ],
                ),
              ),
              // Robert (locked)
              const PopupMenuItem(
                enabled: false,
                value: 'robert',
                child: Row(
                  children: [
                    Icon(Icons.man, color: Color(0xFF7400A5)),
                    SizedBox(width: 8),
                    Text('Robert', style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.lock, color: Colors.grey),
                  ],
                ),
              ),
              // Lonnie (locked)
              const PopupMenuItem(
                enabled: false,
                value: 'lonnie',
                child: Row(
                  children: [
                    Icon(Icons.man, color: Color(0xFF7400A5)),
                    SizedBox(width: 8),
                    Text('Lonnie', style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.lock, color: Colors.grey),
                  ],
                ),
              ),
              // Female Voices Header
              const PopupMenuItem(
                enabled: false,
                child: Text('Female Voices', style: TextStyle(color: Colors.grey)),
              ),
              // Vanessa
              PopupMenuItem(
                value: 'female',
                child: Row(
                  children: [
                    const Icon(Icons.woman, color: Color(0xFF7400A5)),
                    const SizedBox(width: 8),
                    const Text('Vanessa'),
                    const Spacer(),
                    if (_selectedVoice == 'female') const Icon(Icons.check, color: Colors.grey),
                  ],
                ),
              ),
              // Sonia (locked)
              const PopupMenuItem(
                enabled: false,
                value: 'sonia',
                child: Row(
                  children: [
                    Icon(Icons.woman, color: Color(0xFF7400A5)),
                    SizedBox(width: 8),
                    Text('Sonia', style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.lock, color: Colors.grey),
                  ],
                ),
              ),
              // Mabel (locked)
              const PopupMenuItem(
                enabled: false,
                value: 'mabel',
                child: Row(
                  children: [
                    Icon(Icons.woman, color: Color(0xFF7400A5)),
                    SizedBox(width: 8),
                    Text('Mabel', style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.lock, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isSpeakerOn ? Icons.volume_up_outlined : Icons.volume_off,
              color: const Color(0xFF7400A5),
            ),
            onPressed: () async {
              setState(() {
                _isSpeakerOn = !_isSpeakerOn;
              });

              // Immediately update the audio player's volume
              await _audioPlayer.setVolume(_isSpeakerOn ? 1.0 : 0.0);
              print("👂 Speaker toggled: ${_isSpeakerOn ? 'ON' : 'OFF'}, Volume set to: ${_isSpeakerOn ? 1.0 : 0.0}");
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CompleteChatShimmer())
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _pagingController.refresh();
                      },
                      child: Stack(
                        children: [
                          PagedListView<int, ChatMessage>(
                            pagingController: _pagingController,
                            reverse: true,
                            builderDelegate: PagedChildBuilderDelegate<ChatMessage>(
                              itemBuilder: (context, message, index) {
                                // Special case for typing indicator
                                if (message.isTypingIndicator) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
                                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 5.h),
                                      width: 50.w,
                                      height: 30.h,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: JumpingDots(
                                        verticalOffset: -5.h,
                                        color: Colors.white,
                                        radius: 5,
                                        numberOfDots: 3,
                                        animationDuration: const Duration(milliseconds: 200),
                                      ),
                                    ),
                                  );
                                }

                                // Regular message handling
                                final isMe = message.senderId == _currentUserId;
                                final isBot = message.isBot;

                                if (message.userRecommendations != null && message.userRecommendations!.isNotEmpty) {
                                  return Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Message bubble with text
                                      Align(
                                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isMe ? const Color(0xFF7400A5) : Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            message.content.toString(),
                                            style: GoogleFonts.poppins(color: Colors.white),
                                          ),
                                        ),
                                      ),

                                      // User recommendations section
                                      Container(
                                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // User tiles
                                            ...message.userRecommendations!
                                                .map((user) => GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: user.id)));
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(12),
                                                      margin: const EdgeInsets.only(bottom: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade900,
                                                        borderRadius: BorderRadius.circular(15),
                                                        border: Border.all(
                                                          color: const Color(0xFF7400A5).withOpacity(0.5),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          // Avatar
                                                          CircleAvatar(
                                                            backgroundColor: const Color(0xFF7400A5).withOpacity(0.3),
                                                            radius: 20,
                                                            child: Text(
                                                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                                              style: GoogleFonts.poppins(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Flexible(
                                                            // Add Flexible to allow text to wrap properly
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  user.name,
                                                                  style: GoogleFonts.poppins(
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                const SizedBox(height: 4), // Increased spacing
                                                                Text(
                                                                  'Interests: ${user.interests.join(", ")}',
                                                                  style: GoogleFonts.poppins(
                                                                    color: Colors.grey.shade400,
                                                                    fontSize: 12,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                const SizedBox(height: 4), // Increased spacing
                                                                Text(
                                                                  'Matching: ${user.matchingInterestsCount} interest${user.matchingInterestsCount != 1 ? "s" : ""}',
                                                                  style: GoogleFonts.poppins(
                                                                    color: const Color(0xFF7400A5),
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )))
                                                .toList(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isMe ? const Color(0xFF7400A5) : Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        message.content,
                                        style: GoogleFonts.poppins(color: Colors.white),
                                      ),
                                    ),
                                  );
                                }
                              },
                              noItemsFoundIndicatorBuilder: (context) {
                                return Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.12, left: 20),
                                    child: RichText(
                                        textAlign: TextAlign.start,
                                        text: TextSpan(style: const TextStyle(height: 1.4), children: [
                                          TextSpan(text: 'Welcome,\n', style: GoogleFonts.leagueSpartan(fontSize: 40.sp, fontWeight: FontWeight.w900)),
                                          TextSpan(text: "To  ", style: GoogleFonts.leagueSpartan(fontSize: 40.sp, fontWeight: FontWeight.w900)),
                                          TextSpan(
                                            text: "ancoChat\n",
                                            style: GoogleFonts.leagueSpartan(
                                              fontSize: 45, // or use 45.sp if you're using ScreenUtil

                                              fontWeight: FontWeight.w900,
                                              foreground: Paint()
                                                ..shader = const LinearGradient(
                                                  colors: [
                                                    // #E25FB2
                                                    Color(0xFF7E6DF1),
                                                    Color(0xFF7E6DF1), // #7E6DF1
                                                    Color(0xFFE25FB2),
                                                  ],
                                                ).createShader(
                                                  // Adjust these coordinates as needed for the best gradient placement
                                                  const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                                                )
                                                ..style = PaintingStyle.stroke // Outline style
                                                ..strokeWidth = 2, // Outline thickness
                                            ),
                                          ),
                                          TextSpan(text: 'Choose Your Persona', style: GoogleFonts.leagueSpartan(fontSize: 25.sp, fontWeight: FontWeight.w300, color: Colors.grey.shade500)),
                                        ])),
                                  ),
                                );
                              },
                              firstPageErrorIndicatorBuilder: (context) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Error loading messages', style: TextStyle(color: Colors.white)),
                                    ElevatedButton(
                                      onPressed: () => _pagingController.refresh(),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: const Color(0xFF7400A5)),
                          onPressed: () {
                            _isListening ? _stopListening() : _startListening();
                          },
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF7400A5),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pagingController.dispose();
    _audioPlayer.dispose();
    _socketService.onMessageReceived = null; // Clear the message handler
    super.dispose();
  }
}
