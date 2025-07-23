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
  final List<String> profiles;
  final List<String> names;
  const AgoraCallService({
    Key? key,
    required this.channel,
    required this.token,
    required this.callID,
    required this.profiles,
    required this.names,
  }) : super(key: key);

  @override
  _AgoraCallServiceState createState() => _AgoraCallServiceState();
}

class _AgoraCallServiceState extends State<AgoraCallService> {
  Set<int> _remoteUids = {};
  bool _localUserJoined = false;
  late RtcEngine _engine;
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

    socket!.emit('joinCall', {
      'callId': widget.callID,
      'userId': userId,
    });

    socket!.on('callEnded', (data) {
      _onCallEnd();
    });

    socket!.on('userLeft', (data) {
      if (data['userId'] == userId) {
        _onCallEnd();
      }
    });

    socket!.on('error', (data) {
      print('Socket error: ${data['message']}');
    });

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
    if (mounted) Navigator.pop(context);
  }

  Future<void> _endCall() async {
    try {
      await updateCallStatus();
      socket?.emit('callEnded', {
        'callId': widget.callID,
        'userId': userId,
      });
      _onCallEnd();
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> initAgora() async {
    try {
      await [
        Permission.microphone,
        Permission.bluetooth,
        Permission.bluetoothConnect
      ].request();

      if (await Permission.microphone.isDenied) {
        debugPrint("Microphone permission denied");
        return;
      }

      _engine = await createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      await _engine.enableAudio();
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQuality,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUids.remove(remoteUid);
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Error: $err, $msg");
        },
      ));

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

      await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
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
        await _endCall();
        return false;
      },
      child: GroupCallScreen(
        onEndCall: _endCall,
        agoraEngine: _engine,
        remoteUids: _remoteUids,
        call_id: widget.callID,
        profiles: widget.profiles,
        names: widget.names,
        localUserJoined: _localUserJoined,
      ),
    );
  }
}

class GroupCallScreen extends StatefulWidget {
  final VoidCallback onEndCall;
  final dynamic agoraEngine;
  final Set<int> remoteUids;
  final String call_id;
  final List<String> profiles;
  final List<String> names;
  final bool localUserJoined;

  const GroupCallScreen({
    Key? key,
    required this.onEndCall,
    required this.agoraEngine,
    required this.remoteUids,
    required this.call_id,
    required this.profiles,
    required this.names,
    required this.localUserJoined,
  }) : super(key: key);

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;

  void handleSpeakerToggle() async {
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
    await widget.agoraEngine?.setEnableSpeakerphone(isSpeakerOn);
  }

  void handleMuteToggle() {
    setState(() {
      isMuted = !isMuted;
    });
    widget.agoraEngine?.muteLocalAudioStream(isMuted);
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
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                "Group Audio Call",
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Show all participants (local + remote)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                  ),
                  itemCount: 1 + widget.remoteUids.length,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Local user
                      return _buildParticipantTile(
                        profile: widget.profiles.isNotEmpty ? widget.profiles[0] : '',
                        name: widget.names.isNotEmpty ? widget.names[0] : 'You',
                        isLocal: true,
                      );
                    } else {
                      // Remote users
                      final remoteIndex = index - 1;
                      return _buildParticipantTile(
                        profile: widget.profiles.length > remoteIndex + 1 ? widget.profiles[remoteIndex + 1] : '',
                        name: widget.names.length > remoteIndex + 1 ? widget.names[remoteIndex + 1] : 'User',
                        isLocal: false,
                      );
                    }
                  },
                ),
              ),
              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    GestureDetector(
                      onTap: widget.onEndCall,
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
    );
  }

  Widget _buildParticipantTile({required String profile, required String name, required bool isLocal}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
          child: profile.isEmpty ? Icon(Icons.person, size: 32, color: Colors.white) : null,
          backgroundColor: Colors.grey[800],
        ),
        const SizedBox(height: 8),
        Text(
          isLocal ? "$name (You)" : name,
          style: TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
