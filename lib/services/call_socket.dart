// import 'package:flutter/material.dart';
// import 'package:socialmedia/services/agora_Call_Service.dart';
// import 'package:socialmedia/utils/constants.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:shared_preferences/shared_preferences.dart';


// class CallSocketService {
//   IO.Socket? socket;
//   final AgoraCallService _agoraService = AgoraCallService();
//   Function(Map<String, dynamic>)? onIncomingCall;

//   CallSocketService() {
//     // Initialize socket during construction
//     socket = IO.io(
//       '${BASE_URL}',
//       IO.OptionBuilder()
//         .setTransports(['websocket'])
//         .enableAutoConnect()
//         .build()
//     );
//     print("this is your socket");
//   }

//   void initializeCallSocket(BuildContext context) {
//     if (socket == null) return;

//     socket!.on('pickUp', (callData) async {
//       // Incoming call notification
//       if (onIncomingCall != null) {
//         onIncomingCall!(callData);
//       }
//     });
//   }

//   void listenForIncomingCalls(BuildContext context) {
//     if (socket == null) return;
//     print('return nhi hua');

//     socket!.on('pickUp', (callData) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Incoming ${callData['type']} Call'),
//           content: Text('Call from ${callData['from']}'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 // Reject call logic
//                 Navigator.pop(context);
//               },
//               child: Text('Reject'),
//             ),
//             TextButton(
//               onPressed: () {
//                 // Accept call logic
//                 _agoraService.acceptCall(
//                   callId: callData['callId'],
//                   context: context
//                 );
//                 Navigator.pop(context);
//               },
//               child: Text('Accept'),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }