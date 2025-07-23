import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http/http.dart' as http;

class AgoraVidCall extends StatefulWidget {
  final String token;
  final String channel;
  final String callerName;
  final String call_id;
  final String profile;
  final String name;

  const AgoraVidCall({Key? key, required this.channel, required this.token, required this.callerName, required this.call_id, required this.name, required this.profile}) : super(key: key);

  @override
  _AgoraVidCallState createState() => _AgoraVidCallState();
}

class _AgoraVidCallState extends State<AgoraVidCall> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isFrontCamera = true;
  late RtcEngine _engine;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [
      Permission.microphone,
      Permission.camera
    ].request();

    _engine = await createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: 'da20a837fb44462fa7ad25129c429270',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('local user ${connection.localUid} joined');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            startTimer();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
          _timer?.cancel();
          Navigator.pop(context);
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channel,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String formatTime() {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
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
        'callId': widget.call_id,
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

  void handleSpeakerToggle() async {
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
    // Toggle speakerphone
    await _engine.setEnableSpeakerphone(isSpeakerOn);
  }

  Future<void> _onCallEnd() async {
    _timer?.cancel();
    await _engine.leaveChannel();
    await _engine.release();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // Remote Video
              _remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: RtcConnection(channelId: widget.channel),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(widget.profile),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${widget.name}',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 30,
                            ),
                          ),
                          Text(
                            'Ringing...',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

              // Local Video (Small window)
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _localUserJoined
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),

              // Timer
              if (_remoteUid != null)
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    formatTime(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),

              // Control Buttons
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      onPressed: _onSwitchCamera,
                      icon: Icons.switch_camera,
                      backgroundColor: Colors.grey[800]!,
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: handleSpeakerToggle,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSpeakerOn ? Color(0xFF7400A5) : Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      onPressed: _onToggleMute,
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      backgroundColor: _isMuted ? Colors.red : Colors.grey[800]!,
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      onPressed: () async {
                        await updateCallStatus();
                        _onCallEnd();
                      },
                      icon: Icons.call_end,
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
              ),

              // Swipe up text
              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text(
                  'Swipe up to show chat',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
