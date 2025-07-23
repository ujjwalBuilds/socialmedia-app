import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

const appId = "da20a837fb44462fa7ad25129c429270";

class AgoraCallService extends StatefulWidget {
  final String token;
  final String channel;
  final String callID;
  final String profile;
  final String name;
  const AgoraCallService({Key? key, required this.channel, required this.token, required this.callID, required this.profile, required this.name}) : super(key: key);

  @override
  _AgoraCallServiceState createState() => _AgoraCallServiceState();
}

class _AgoraCallServiceState extends State<AgoraCallService> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _isInitialized = false;
  IO.Socket? socket;
  String? userId;

  @override
  void initState() {
    super.initState();
    initAgora();
    _setupSocketConnection();
  }

  Future<void> _setupSocketConnection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    String? token = prefs.getString('user_token');
    String? socketToken = prefs.getString('socketToken');

    if (userId == null || token == null) {
      print("User ID or token not found in SharedPreferences");
      return;
    }

    socket = IO.io(
        BASE_URL,
        IO.OptionBuilder()
            .setTransports([
              'websocket'
            ])
            .setAuth({
              'token': socketToken
            })
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(double.infinity)
            .setReconnectionDelay(1000)
            .build());

    socket!.connect();

    // Join call room
    socket!.emit('joinCall', {
      'callId': widget.callID,
      'userId': userId,
    });

    // Listen for call ended event (for all participants)
    socket!.on('callEnded', (data) {
      print('Call ended for all: ${data['message']}');
      _onCallEnd();
    });

    // Listen for user left event (when specific users leave)
    socket!.on('userLeft', (data) {
      print('User left: ${data['userId']}');
      _onCallEnd(); // Navigate out when the other user leaves
    });

    // Listen for socket errors
    socket!.on('error', (data) {
      print('Socket error: ${data['message']}');
    });

    // Listen for connection events
    socket!.onConnect((_) {
      print('Socket connected');
    });

    socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  Future<void> _onCallEnd() async {
    await _engine.leaveChannel();
    await _engine.release();
    Navigator.pop(context);
  }

  Future<void> _endCall() async {
    try {
      print("End call button pressed");

      // First update the call status in the database
      await updateCallStatus();

      // Emit call ended event to socket
      socket?.emit('callEnded', {
        'callId': widget.callID,
        'userId': userId,
      });

      _onCallEnd();
    } catch (e) {
      print("Error ending call: $e");
      // Ensure we still exit the call screen even if there's an error
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> initAgora() async {
    try {
      // Request permissions first
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

      // Create and initialize the engine
      _engine = await createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Enable audio features
      await _engine.enableAudio();
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQuality,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // Register event handlers
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
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left");
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Error: $err, $msg");
          // Handle error appropriately
          if (err == ErrorCodeType.errJoinChannelRejected) {
            debugPrint("Failed to join channel. Please check your token and channel name.");
          }
        },
      ));

      // Join the channel
      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channel,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
        uid: 0,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
      // Handle initialization error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize call. Please try again.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

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
        print("Call status updated successfully: ${response.body}");
      } else {
        print("Failed to update call status: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error updating call status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Handle back button press the same as end call
        await _endCall();
        return false; // We handle the navigation ourselves
      },
      child: CallScreen(
        callerName: 'Audio Call',
        onEndCall: _endCall,
        agoraEngine: _engine,
        remoteUid: _remoteUid,
        call_id: widget.callID,
        profile: widget.profile,
        name: widget.name,
        localUserJoined: _localUserJoined,
      ),
    );
  }
}

class CallScreen extends StatefulWidget {
  final String callerName;
  final VoidCallback onEndCall;
  final dynamic agoraEngine; // Replace with your actual Agora engine type
  final int? remoteUid;
  final String call_id;
  final String profile;
  final String name;
  final bool localUserJoined;

  const CallScreen({Key? key, required this.callerName, required this.onEndCall, required this.agoraEngine, required this.remoteUid, required this.profile, required this.call_id, required this.name, required this.localUserJoined}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  int secondsElapsed = 0;
  Timer? timer;
  bool isSpeakerOn = false;
  bool isCallConnected = false;

  @override
  void initState() {
    super.initState();
    // Don't start timer immediately, wait for both users to join
  }

  @override
  void didUpdateWidget(CallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start timer only when both local user and remote user have joined
    if (widget.localUserJoined && widget.remoteUid != null && !isCallConnected) {
      setState(() {
        isCallConnected = true;
        secondsElapsed = 0; // Reset timer when call actually connects
      });
      startTimer();
    }
  }

  void startTimer() {
    timer?.cancel(); // Cancel any existing timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secondsElapsed++;
      });
    });
  }

  String formatTime() {
    int hours = secondsElapsed ~/ 3600;
    int minutes = (secondsElapsed % 3600) ~/ 60;
    int seconds = secondsElapsed % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void handleSpeakerToggle() async {
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
    // Toggle speakerphone
    await widget.agoraEngine?.setEnableSpeakerphone(isSpeakerOn);
  }

  void handleMuteToggle() {
    setState(() {
      isMuted = !isMuted;
    });
    // Implement Agora mute logic here
    widget.agoraEngine?.muteLocalAudioStream(isMuted);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a1a1a),
                Color(0xFF0a0a0a)
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Caller Info
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(widget.profile),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.name,
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCallConnected ? formatTime() : "Ringing...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                // Call Controls
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mute Button
                      GestureDetector(
                        onTap: handleMuteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isMuted ? Colors.grey[700] : Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: handleSpeakerToggle,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSpeakerOn ? Color(0xFF7400A5) : Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // End Call Button
                      GestureDetector(
                        onTap: () {
                          print("End call button tapped");
                          widget.onEndCall();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
