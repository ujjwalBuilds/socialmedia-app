import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class CompleteChatShimmer extends StatelessWidget {
  const CompleteChatShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: SvgPicture.asset(
            'assets/icons/bondchat_star.svg',
            width: 50.w,
            height: 50.h,
          ),
        ),
      ),
    );
  }
}

// class ChatMessagesShimmer extends StatelessWidget {
//   const ChatMessagesShimmer({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Number of shimmer items to show
//     final int itemCount = 8;

//     return Shimmer.fromColors(
//       baseColor: const Color.fromARGB(255, 159, 33, 212),
//       highlightColor: const Color.fromARGB(215, 201, 92, 248),
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: itemCount,
//         reverse: true,
//         itemBuilder: (context, index) {
//           // Alternate between left and right alignment
//           final bool isLeftAligned = index % 2 == 0;
          
//           // Vary the width of messages
//           final double widthFactor = 0.3 + (index % 3) * 0.15;
//           final double width = MediaQuery.of(context).size.width * widthFactor;
          
//           // Vary the height to simulate different message lengths
//           final double height = 40.0 + (index % 4) * 10.0;
          
//           return Align(
//             alignment: isLeftAligned ? Alignment.bottomLeft : Alignment.bottomRight,
//             child: Container(
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               width: width,
//               height: height,
//               decoration: BoxDecoration(
//                 color: Color(0xFF7400A5),
//                 // Different border radius for left/right messages
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(16),
//                   topRight: Radius.circular(16),
//                   bottomLeft: isLeftAligned ? Radius.circular(4) : Radius.circular(16),
//                   bottomRight: isLeftAligned ? Radius.circular(16) : Radius.circular(4),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class CompleteChatShimmer extends StatelessWidget {
  const CompleteChatShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: SvgPicture.asset(
            'assets/icons/bondchat_star.svg',
            width: 50.w,
            height: 50.h,
          ),
        ),
      ),
    );
  }
}

// class ChatMessagesShimmer extends StatelessWidget {
//   const ChatMessagesShimmer({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Number of shimmer items to show
//     final int itemCount = 8;

//     return Shimmer.fromColors(
//       baseColor: const Color.fromARGB(255, 159, 33, 212),
//       highlightColor: const Color.fromARGB(215, 201, 92, 248),
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: itemCount,
//         reverse: true,
//         itemBuilder: (context, index) {
//           // Alternate between left and right alignment
//           final bool isLeftAligned = index % 2 == 0;
          
//           // Vary the width of messages
//           final double widthFactor = 0.3 + (index % 3) * 0.15;
//           final double width = MediaQuery.of(context).size.width * widthFactor;
          
//           // Vary the height to simulate different message lengths
//           final double height = 40.0 + (index % 4) * 10.0;
          
//           return Align(
//             alignment: isLeftAligned ? Alignment.bottomLeft : Alignment.bottomRight,
//             child: Container(
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               width: width,
//               height: height,
//               decoration: BoxDecoration(
//                 color: Color(0xFF7400A5),
//                 // Different border radius for left/right messages
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(16),
//                   topRight: Radius.circular(16),
//                   bottomLeft: isLeftAligned ? Radius.circular(4) : Radius.circular(16),
//                   bottomRight: isLeftAligned ? Radius.circular(16) : Radius.circular(4),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

