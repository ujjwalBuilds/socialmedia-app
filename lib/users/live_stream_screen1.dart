// import 'dart:convert';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/services/agora_live_Service.dart';
// import 'package:socialmedia/utils/constants.dart';

// class LiveStreamScreen extends StatefulWidget {
//   @override
//   _LiveStreamScreenState createState() => _LiveStreamScreenState();
// }

// class _LiveStreamScreenState extends State<LiveStreamScreen> {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;

//   @override
//   void initState() {
//     super.initState();
//     initializeCamera();
//   }

//   Future<void> initializeCamera() async {
//     try {
//       print("Initializing camera...");
//       _cameras = await availableCameras();
//       print("Available cameras: $_cameras");

//       // Find the front camera and set it as the default
//       CameraDescription? frontCamera;
//       for (var camera in _cameras!) {
//         if (camera.lensDirection == CameraLensDirection.front) {
//           frontCamera = camera;
//           break;
//         }
//       }

//       if (frontCamera != null) {
//         _cameraController =
//             CameraController(frontCamera, ResolutionPreset.high);
//         await _cameraController!.initialize();
//         print("Front camera initialized successfully.");
//         if (mounted) {
//           setState(() {});
//         }
//       } else {
//         print("No front camera found, initializing the first available camera");
//         // Fallback to the first available camera
//         _cameraController =
//             CameraController(_cameras![0], ResolutionPreset.high);
//         await _cameraController!.initialize();
//         if (mounted) {
//           setState(() {});
//         }
//       }
//     } catch (e) {
//       print("Error initializing camera: $e");
//     }
//   }

//   Future<void> startLiveStream() async {
//     // Fetch userId and token from SharedPreferences
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? userId = prefs.getString('user_id');
//     String? token = prefs.getString('user_token');

//     if (userId == null || token == null) {
//       print("User ID or token is missing");
//       return;
//     }

//     // Create headers with userId and token
//     Map<String, String> headers = {
//       'userid': userId,
//       'token': token,
//     };

//     // Endpoint URL
//     String url = '${BASE_URL}api/start-live-stream';

//     // Make POST request
//     try {
//       var response = await http.post(
//         Uri.parse(url),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         // Parse response
//         Map<String, dynamic> responseBody = json.decode(response.body);
//         print("Message: ${responseBody['message']}");
//         print("Channel Name: ${responseBody['channelName']}");
//         print(userId);
//         print("Token: ${responseBody['token']}");
//         print('aagyaaaaaaaa');
//         final agoratoken = responseBody['token'];
//         final agorachannel = responseBody['channelName'];
//         // await _agoraLiveService.joinLiveChannel(
//         //     channelName: agorachannel,
//         //     token: agoratoken,
//         //     isBroadcaster: true);

//         print('jaaraaaaaaa');
//         Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => LiveAyush(
//                     token: agoratoken,
//                     channel: agorachannel,
//                     isboradcaster: true)));
//       } else {
//         print("Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("Error: $e");
//     }
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

  // @override
  // Widget build(BuildContext context) {
  //   final userProvider = Provider.of<UserProviderall>(context, listen: false);
  //   return Scaffold(
  //     backgroundColor: Colors.black,
  //     body: Padding(
  //       padding:
  //           const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
  //       child: Row(
  //         children: [
  //           CircleAvatar(
  //             backgroundImage: userProvider.userProfile != null
  //                 ? NetworkImage(userProvider.userProfile!)
  //                 : AssetImage('assets/avatar/1.png') as ImageProvider,
  //           ),
  //           SizedBox(width: 10),
  //           Text(
  //             'Go Live',
  //             style:
  //                 GoogleFonts.poppins(color: Colors.white, fontSize: 16),
  //           ),
  //           Spacer(),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: Text(
  //               'Cancel',
  //               style: GoogleFonts.poppins(
  //                   color: Colors.white, fontSize: 14),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //     }
  

import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/services/agora_live_Service.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';

class LiveStreamScreen extends StatefulWidget {
  @override
  _LiveStreamScreenState createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      print("Initializing camera...");
      _cameras = await availableCameras();
      print("Available cameras: $_cameras");

      // Find the front camera and set it as the default
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      if (frontCamera != null) {
        _cameraController =
            CameraController(frontCamera, ResolutionPreset.high);
        await _cameraController!.initialize();
        print("Front camera initialized successfully.");
        if (mounted) {
          setState(() {});
        }
      } else {
        print("No front camera found, initializing the first available camera");
        // Fallback to the first available camera
        _cameraController =
            CameraController(_cameras![0], ResolutionPreset.high);
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> startLiveStream() async {
    // Fetch userId and token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? token = prefs.getString('user_token');

    if (userId == null || token == null) {
      print("User ID or token is missing");
      return;
    }

    // Create headers with userId and token
    Map<String, String> headers = {
      'userid': userId,
      'token': token,
    };

    // Endpoint URL
    String url = '${BASE_URL}api/start-live-stream';

    // Make POST request
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Parse response
        Map<String, dynamic> responseBody = json.decode(response.body);
        print("Message: ${responseBody['message']}");
        print("Channel Name: ${responseBody['channelName']}");
        print(userId);
        print("Token: ${responseBody['token']}");
        print('aagyaaaaaaaa');
        final agoratoken = responseBody['token'];
        final agorachannel = responseBody['channelName'];
        // await _agoraLiveService.joinLiveChannel(
        //     channelName: agorachannel,
        //     token: agoratoken,
        //     isBroadcaster: true);

        print('jaaraaaaaaa');
      // await  SocketService().connect();
      //  SocketService().openStream(agorachannel); 
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => LiveAyush(
                    token: agoratoken,
                    channel: agorachannel,
                    isboradcaster: true)));
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Profile and Cancel Button
              Padding(
                padding:
                     EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 10.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: userProvider.userProfile != null
                          ? NetworkImage(userProvider.profilePic!)
                          : AssetImage('assets/avatar/1.png') as ImageProvider,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Go Live',
      
                      style:
                          GoogleFonts.poppins(color: Colors.white, fontSize: 16.sp),
                    ),
                    Spacer(),
                    OutlinedButton(
                      
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14.sp,fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
      
              // Camera Preview (Centered)
              Expanded(
                child: Center(
                  child: _cameraController != null &&
                          _cameraController!.value.isInitialized
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..scale(-1.0, 1.0, 1.0), // Flip horizontally
                          child: CameraPreview(_cameraController!),
                        )
                      : CircularProgressIndicator(),
                ),
              ),
      
              SizedBox(height: 20),
      
              // Controls: Add Friends + Camera + Mic + Photo Button
              /*  FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _controlButton(Icons.person_add, "Add friends"),
                    SizedBox(width: 15),
                    _circleIcon(Icons.videocam),
                    SizedBox(width: 15),
                    _circleIcon(Icons.mic),
                    SizedBox(width: 15),
                    _circleIcon(Icons.camera_alt),
                  ],
                ),
              ),*/
      
              SizedBox(height: 20),
      
              // Go Live Button
              SizedBox(
                width: 300,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    print("Go Live Pressed");
                    startLiveStream();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7400A5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Go Live",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, String text) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

Widget _circleIcon(IconData icon) {
    return CircleAvatar(
      backgroundColor: Colors.grey[800],
      radius: 24,
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}