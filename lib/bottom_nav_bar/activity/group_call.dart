import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group_call_bottom_sheet.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';

const appId = "da20a837fb44462fa7ad25129c429270";
// Replace with your actual base URL

class CallParticipant {
  final String userId;
  final String name;
  final String? profilePic;
  bool isVideoOn;
  bool isAudioOn;

  CallParticipant({
    required this.userId,
    required this.name,
    this.profilePic,
    this.isVideoOn = true,
    this.isAudioOn = true,
  });
}

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final Map<String, Participant> participantsMap;
  final String currentUserId;
  final String token;
  final String channel;
  final String callID;
  final bool isVideoCall; // Parameter to determine if it's a video call or voice call

  const VideoCallScreen({
    Key? key,
    required this.roomId,
    required this.participantsMap,
    required this.currentUserId,
    required this.token,
    required this.channel,
    required this.callID,
    this.isVideoCall = false, // Default to voice call
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // List of active call participants
  List<CallParticipant> _activeParticipants = [];

  // Agora properties
  late RtcEngine _engine;
  bool _localUserJoined = false;
  Set<int> _remoteUids = {};
  bool _isMuted = false;
  bool _isFrontCamera = true;
  bool _isInitialized = false;
  bool _isSpeakerOn = false;

  // Call timer
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    // Add current user as the first participant
    final currentParticipant = widget.participantsMap[widget.currentUserId];
    if (currentParticipant != null) {
      _activeParticipants.add(
        CallParticipant(
          userId: widget.currentUserId,
          name: currentParticipant.name ?? 'You',
          profilePic: currentParticipant.profilePic,
          isVideoOn: widget.isVideoCall, // Video on only if it's a video call
        ),
      );
    } else {
      // Fallback if current user isn't in the participants map
      _activeParticipants.add(
        CallParticipant(
          userId: widget.currentUserId,
          name: 'You',
          isVideoOn: widget.isVideoCall, // Video on only if it's a video call
        ),
      );
    }

    // Initialize Agora
    initAgora();
  }

  // Format time for call duration
  String formatTime() {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Start the call timer
  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  // Initialize Agora
  Future<void> initAgora() async {
    // Request permissions based on call type
    if (widget.isVideoCall) {
      await [
        Permission.microphone,
        Permission.camera
      ].request();

      // Check if permissions were granted
      if (await Permission.microphone.isDenied || await Permission.camera.isDenied) {
        debugPrint("Microphone or Camera permission denied");
        return;
      }
    } else {
      await [
        Permission.microphone,
        Permission.bluetooth,
        Permission.bluetoothConnect
      ].request();

      // Check if permissions were granted
      if (await Permission.microphone.isDenied) {
        debugPrint("Microphone permission denied");
        return;
      }
    }

    _engine = await createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Set up event handlers
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint('Local user joined: ${connection.localUid}');
        setState(() {
          _localUserJoined = true;
        });
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("Remote user $remoteUid joined");
        setState(() {
          _remoteUids.add(remoteUid);
          // Start timer when a remote user joins
          if (_remoteUids.isNotEmpty && _timer == null) {
            startTimer();
          }
        });
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint("Remote user $remoteUid left");
        setState(() {
          _remoteUids.remove(remoteUid);
        });

        // If no remote users are left, consider ending the call
        if (_remoteUids.isEmpty) {
          _timer?.cancel();
          updateCallStatus(); // Update call status to 'ended'
          // Don't auto-close, let the user end the call manually
        }
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint("Error: $err, $msg");
      },
    ));

    // Configure for video if it's a video call
    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      // For voice call, just enable audio
      await _engine.enableAudio();
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQuality,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
    }

    // Join the channel with appropriate options
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channel,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: widget.isVideoCall, // Only publish camera if it's a video call
        autoSubscribeAudio: true,
        autoSubscribeVideo: widget.isVideoCall, // Only subscribe to video if it's a video call
      ),
      uid: 0,
    );

    setState(() {
      _isInitialized = true;
    });
  }

  // Toggle mute/unmute
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _engine.muteLocalAudioStream(_isMuted);

      // Update the current user's audio status
      final currentUser = _activeParticipants.firstWhere((p) => p.userId == widget.currentUserId, orElse: () => _activeParticipants.first);
      currentUser.isAudioOn = !_isMuted;
    });
  }

  // Toggle speaker
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      _engine.setEnableSpeakerphone(_isSpeakerOn);
    });
  }

  // Switch camera (front/back)
  void _switchCamera() {
    _engine.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  // Update call status to the server
  Future<void> updateCallStatus() async {
    final String url = '${BASE_URL}api/update-call-status';

    try {
      // Get userId and token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? token = prefs.getString('user_token');

      if (userId == null || token == null) {
        throw Exception("User ID or token not found in SharedPreferences");
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'token': token,
        'userId': userId,
      };

      Map<String, dynamic> body = {
        'callId': widget.callID,
        'status': 'ended',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("Call status updated successfully: ${response.body}");
      } else {
        debugPrint("Failed to update call status: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error updating call status: $e");
    }
  }

  // End call
  Future<void> _endCall() async {
    _timer?.cancel();
    await updateCallStatus();
    await _engine.leaveChannel();
    await _engine.release();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Clean up resources
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // Add a participant to the call
  void _addParticipant(String userId) {
    if (_activeParticipants.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Maximum 6 participants allowed'))),
      );
      return;
    }

    final participant = widget.participantsMap[userId];
    if (participant != null && !_activeParticipants.any((p) => p.userId == userId)) {
      setState(() {
        _activeParticipants.add(
          CallParticipant(
            userId: userId,
            name: participant.name ?? 'Unknown',
            profilePic: participant.profilePic,
            isVideoOn: widget.isVideoCall, // Video on only if it's a video call
          ),
        );
      });
    }
  }

  // Show the add friends bottom sheet
  void _showAddFriendsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SafeArea(
          child: AddFriendsBottomSheet(
            participantsMap: widget.participantsMap,
            onInvite: (userId) {
              Navigator.pop(context); // Close the bottom sheet
              _addParticipant(userId);
            },
            excludeUserIds: _activeParticipants.map((p) => p.userId).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Call control header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      onPressed: () => _endCall(),
                    ),
                    Column(
                      children: [
                        Text(
                          widget.isVideoCall ? 'Video Call' : 'Voice Call',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_timer != null)
                          Text(
                            formatTime(),
                            style: GoogleFonts.roboto(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14.sp,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.person_add, color: Colors.white),
                      onPressed: _showAddFriendsSheet,
                    ),
                  ],
                ),
              ),

              // Video/Voice grid
              Expanded(
                child: _buildVideoGrid(),
              ),

              // Call controls
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (widget.isVideoCall)
                      _buildControlButton(
                        icon: Icons.flip_camera_ios,
                        label: 'Flip',
                        onPressed: _switchCamera,
                      ),
                    if (!widget.isVideoCall)
                      _buildControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                        onPressed: _toggleSpeaker,
                      ),
                    if (widget.isVideoCall)
                      _buildControlButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        onPressed: () {},
                      ),
                    _buildControlButton(
                      icon: Icons.call_end,
                      label: 'End',
                      color: Colors.red,
                      onPressed: _endCall,
                    ),
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      onPressed: _toggleMute,
                    ),
                    _buildControlButton(
                      icon: Icons.add,
                      label: 'Add',
                      onPressed: _showAddFriendsSheet,
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

  Widget _buildVideoGrid() {
    // Based on number of participants, determine the grid layout
    switch (_activeParticipants.length) {
      case 1:
        return _buildSingleParticipantView();
      case 2:
        return _buildTwoParticipantView();
      case 3:
        return _buildThreeParticipantView();
      case 4:
        return _buildFourParticipantView();
      case 5:
      case 6:
        return _buildSixParticipantView();
      default:
        return Center(child: Text('No participants', style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildSingleParticipantView() {
    return _buildParticipantTile(_activeParticipants[0], fullScreen: true);
  }

  Widget _buildTwoParticipantView() {
    return Column(
      children: [
        Expanded(child: _buildParticipantTile(_activeParticipants[0])),
        Expanded(child: _buildParticipantTile(_activeParticipants[1])),
      ],
    );
  }

  Widget _buildThreeParticipantView() {
    return Column(
      children: [
        Expanded(child: _buildParticipantTile(_activeParticipants[0])),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildParticipantTile(_activeParticipants[1])),
              Expanded(child: _buildParticipantTile(_activeParticipants[2])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourParticipantView() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildParticipantTile(_activeParticipants[0])),
              Expanded(child: _buildParticipantTile(_activeParticipants[1])),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildParticipantTile(_activeParticipants[2])),
              Expanded(child: _buildParticipantTile(_activeParticipants[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSixParticipantView() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildParticipantTile(_activeParticipants[0])),
              Expanded(child: _buildParticipantTile(_activeParticipants[1])),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildParticipantTile(_activeParticipants[2])),
              Expanded(child: _buildParticipantTile(_activeParticipants[3])),
            ],
          ),
        ),
        if (_activeParticipants.length > 4)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildParticipantTile(_activeParticipants[4])),
                Expanded(
                  child: _activeParticipants.length > 5 ? _buildParticipantTile(_activeParticipants[5]) : Container(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantTile(CallParticipant participant, {bool fullScreen = false}) {
    // Check if this is the local user or a remote user
    bool isLocalUser = participant.userId == widget.currentUserId;
    bool hasJoined = isLocalUser ? _localUserJoined : _remoteUids.isNotEmpty;

    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(fullScreen ? 0 : 8),
      ),
      child: Stack(
        children: [
          // For video calls with video enabled, show the video surface
          if (widget.isVideoCall && participant.isVideoOn)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(fullScreen ? 0 : 8),
                child: isLocalUser
                    ? _localUserJoined
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : Container(color: Colors.grey[800])
                    : _remoteUids.isNotEmpty
                        ? AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: _engine,
                              canvas: VideoCanvas(uid: _remoteUids.first),
                              connection: RtcConnection(channelId: widget.channel),
                            ),
                          )
                        : Container(color: Colors.grey[800]),
              ),
            )
          // For voice calls or when video is off, show the avatar
          else
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: hasJoined ? Color(0xFF7400A5) : Colors.grey,
                backgroundImage: participant.profilePic != null ? NetworkImage(participant.profilePic!) : null,
                child: participant.profilePic == null
                    ? Text(
                        participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),

          // Participant name and status overlay
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // Audio mute indicator
                  if (!participant.isAudioOn)
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.mic_off, color: Colors.white, size: 14),
                    ),
                  // Video off indicator (for video calls)
                  if (widget.isVideoCall && !participant.isVideoOn)
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.videocam_off, color: Colors.white, size: 14),
                    ),
                  Text(
                    participant.name,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color == Colors.red ? Colors.red : Colors.grey[800],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          label,
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 12.sp),
        ),
      ],
    );
  }
}
