// import 'dart:ui';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/searchpage.dart';
// import 'package:socialmedia/users/Bondchat.dart';
// import 'package:socialmedia/users/profile_screen.dart';

// class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
//   CustomAppBar({super.key});

//   @override
//   Size get preferredSize => const Size.fromHeight(70);

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
// }

// class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
//   late UserProviderall userProvider;
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;

//   @override
//   void initState() {
//     super.initState();
//     userProvider = Provider.of<UserProviderall>(context, listen: false);
//     userProvider.loadUserData().then((_) {
//       setState(() {}); // Refresh UI after loading data
//     });
//     _blinkController = AnimationController(
//       duration: const Duration(milliseconds: 850),
//       vsync: this,
//     )..repeat(reverse: true);
//     _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProviderall>(context, listen: false);

//     return ClipRRect(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           height: 110,
//           decoration: BoxDecoration(
//             color: Theme.of(context).brightness == Brightness.dark ? Colors.black45.withOpacity(0.7) : Colors.white,
//           ),
//           child: AppBar(
//             automaticallyImplyLeading: false,
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             flexibleSpace: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   children: [
//                     Row(
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.only(bottom: 5.0.h),
//                           child: SizedBox(
//                               height: 40.h,
//                               child: SvgPicture.asset(
//                                 'assets/images/bondlogog.svg', // Use the SVG file path
//                                 width: 10.w, // Adjust size as needed
//                                 height: 35.h,
//                               )),
//                         ),
//                         SizedBox(width: 1.w),
//                         Text.rich(
//                           TextSpan(
//                             text: "BondBridge",
//                             style: GoogleFonts.leagueSpartan(
//                               fontSize: 28.sp, // Adjust based on your needs
//                               fontWeight: FontWeight.w800,
//                               foreground: Paint()
//                                 ..shader = const LinearGradient(
//                                   begin: Alignment.bottomLeft,
//                                   end: Alignment.topRight,
//                                   colors: [
//                                     Color(0xFF3B01B7), // Dark purple (bottom left)
//                                     Color(0xFF5E00FF), // Purple
//                                     Color(0xFFBA19EB), // Pink-purple
//                                     Color(0xFFDD0CC8), // Pink (top right)
//                                   ],
//                                   // stops: [1.0, 0.69, 0.34, 0.0]
//                                 ).createShader(
//                                   const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
//                                 ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
//                               decoration: BoxDecoration(
//                                 border: Border.all(
//                                   color: const Color(0xFF7400A5),
//                                   width: 2,
//                                 ),
//                                 borderRadius: BorderRadius.circular(15.sp),
//                               ),
//                               child: InkWell(
//                                 onTap: () {
//                                   Navigator.push(context, MaterialPageRoute(builder: (context) => const BondChatScreen()));
//                                 },
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     FadeTransition(
//                                       opacity: _blinkAnimation,
//                                       child: Row(
//                                         children: [
//                                           SvgPicture.asset(
//                                             'assets/icons/bondchat_star.svg',
//                                             width: 15.w,
//                                             height: 15.h,
//                                             color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                                           ),
//                                           SizedBox(width: 5.w),
//                                           Text(
//                                             'BondChat',
//                                             style: GoogleFonts.roboto(
//                                               fontSize: 16.sp,
//                                               fontWeight: FontWeight.bold,
//                                               color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 8.w),
//                             Padding(
//                               padding: EdgeInsets.only(top: 6.12.h),
//                               child: IconButton(
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(builder: (context) => const UserSearchScreen()),
//                                   );
//                                 },
//                                 icon: const Icon(Icons.search),
//                               ),
//                             ),
//                           ],
//                         ),
//                         // Text positioned directly under BondChat button
//                         Padding(
//                           padding: EdgeInsets.only(right: 68.w), // Adjust right padding to align under BondChat
//                           child: Text(
//                             'Hi I am BondChat',
//                             style: GoogleFonts.roboto(
//                               fontSize: 12.sp, // Smaller font to prevent overflow
//                               color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _BlinkingText extends StatefulWidget {
//   @override
//   __BlinkingTextState createState() => __BlinkingTextState();
// }

// class __BlinkingTextState extends State<_BlinkingText> with SingleTickerProviderStateMixin {
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _blinkController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//     _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
//   }

//   @override
//   void dispose() {
//     _blinkController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _blinkAnimation,
//       child: Text(
//         'Hi! I am BondChat',
//         style: GoogleFonts.roboto(
//           fontSize: 12.sp,
//           color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//         ),
//       ),
//     );
//   }
// }


// import 'dart:ui';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/searchpage.dart';
// import 'package:socialmedia/users/Bondchat.dart';
// import 'package:socialmedia/users/profile_screen.dart';

// class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
//   CustomAppBar({super.key});

//   @override
//   Size get preferredSize =>  Size.fromHeight(90.h);

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
// }

// class _CustomAppBarState extends State<CustomAppBar> with TickerProviderStateMixin {
//   late UserProviderall userProvider;
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;
//   late AnimationController _scaleController;
//   late Animation<double> _scaleAnimation;
//   late AnimationController _slideController;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     userProvider = Provider.of<UserProviderall>(context, listen: false);
//     userProvider.loadUserData().then((_) {
//       setState(() {}); // Refresh UI after loading data
//     });

//     // Original blinking animation for BondChat button
//     _blinkController = AnimationController(
//       duration: const Duration(milliseconds: 850),
//       vsync: this,
//     )..repeat(reverse: true);
//     _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);

//     // Scale animation for hanging label
//     _scaleController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     )..repeat(reverse: true);
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
//       CurvedAnimation(parent: _scaleController, curve: Curves.elasticInOut),
//     );

//     // Slide animation for hanging label
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0),
//       end: const Offset(0, 0.1),
//     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _blinkController.dispose();
//     _scaleController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProviderall>(context, listen: false);

//     return ClipRRect(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           height: 110,
//           decoration: BoxDecoration(
//             color: Theme.of(context).brightness == Brightness.dark ? Colors.black45.withOpacity(0.7) : Colors.white,
//           ),
//           child: AppBar(
//             toolbarHeight: 120.h,
//             automaticallyImplyLeading: false,
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             flexibleSpace: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   children: [
//                     Row(
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.only(bottom: 5.0.h),
//                           child: SizedBox(
//                               height: 40.h,
//                               child: SvgPicture.asset(
//                                 'assets/images/bondlogog.svg', // Use the SVG file path
//                                 width: 10.w, // Adjust size as needed
//                                 height: 35.h,
//                               )),
//                         ),
//                         SizedBox(width: 1.w),
//                         Text.rich(
//                           TextSpan(
//                             text: "BondBridge",
//                             style: GoogleFonts.leagueSpartan(
//                               fontSize: 28.sp, // Adjust based on your needs
//                               fontWeight: FontWeight.w800,
//                               foreground: Paint()
//                                 ..shader = const LinearGradient(
//                                   begin: Alignment.bottomLeft,
//                                   end: Alignment.topRight,
//                                   colors: [
//                                     Color(0xFF3B01B7), // Dark purple (bottom left)
//                                     Color(0xFF5E00FF), // Purple
//                                     Color(0xFFBA19EB), // Pink-purple
//                                     Color(0xFFDD0CC8), // Pink (top right)
//                                   ],
//                                   // stops: [1.0, 0.69, 0.34, 0.0]
//                                 ).createShader(
//                                   const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
//                                 ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),
//                     Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
//                                   decoration: BoxDecoration(
//                                     border: Border.all(
//                                       color: const Color(0xFF7400A5),
//                                       width: 2,
//                                     ),
//                                     borderRadius: BorderRadius.circular(15.sp),
//                                   ),
//                                   child: InkWell(
//                                     onTap: () {
//                                       Navigator.push(context, MaterialPageRoute(builder: (context) => const BondChatScreen()));
//                                     },
//                                     child: Row(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         FadeTransition(
//                                           opacity: _blinkAnimation,
//                                           child: Row(
//                                             children: [
//                                               SvgPicture.asset(
//                                                 'assets/icons/bondchat_star.svg',
//                                                 width: 15.w,
//                                                 height: 15.h,
//                                                 color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                                               ),
//                                               SizedBox(width: 5.w),
//                                               Text(
//                                                 'BondChat',
//                                                 style: GoogleFonts.roboto(
//                                                   fontSize: 16.sp,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 8.w),
//                                 Padding(
//                                   padding: EdgeInsets.only(top: 6.12.h),
//                                   child: IconButton(
//                                     onPressed: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(builder: (context) => const UserSearchScreen()),
//                                       );
//                                     },
//                                     icon: const Icon(Icons.search),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         // Enhanced hanging label
//                         Positioned(
//                           top: 35.h,
//                           right: 50.w,
//                           child: SlideTransition(
//                             position: _slideAnimation,
//                             child: ScaleTransition(
//                               scale: _scaleAnimation,
//                               child: Container(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 8.w,
//                                   vertical: 3.h,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       const Color(0xFF7400A5).withOpacity(0.9),
//                                       const Color(0xFFBA19EB).withOpacity(0.9),
//                                     ],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   borderRadius: BorderRadius.circular(10.r),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: const Color(0xFF7400A5).withOpacity(0.4),
//                                       blurRadius: 6,
//                                       offset: const Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     // Icon(
//                                     //   Icons.chat_bubble_outline,
//                                     //   size: 10.sp,
//                                     //   color: Colors.white,
//                                     // ),
//                                     SizedBox(width: 4.w),
//                                     Text(
//                                       'Hey, I\'m your smart AI assitant,\n click here & explore!',
//                                       style: GoogleFonts.roboto(
//                                         fontSize: 10.sp,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.white,
//                                         shadows: [
//                                           Shadow(
//                                             color: Colors.black.withOpacity(0.3),
//                                             offset: const Offset(0, 1),
//                                             blurRadius: 2,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         // Connecting line
//                         Positioned(
//                           top: 32.h,
//                           right: 85.w,
//                           child: Container(
//                             width: 1.5.w,
//                             height: 6.h,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   const Color(0xFF7400A5).withOpacity(0.6),
//                                   const Color(0xFF7400A5).withOpacity(0.2),
//                                 ],
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _BlinkingText extends StatefulWidget {
//   @override
//   __BlinkingTextState createState() => __BlinkingTextState();
// }

// class __BlinkingTextState extends State<_BlinkingText> with SingleTickerProviderStateMixin {
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _blinkController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//     _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
//   }

//   @override
//   void dispose() {
//     _blinkController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _blinkAnimation,
//       child: Text(
//         'Hey, I\'m your smart AI assitant,\n click here & explore!',
//         style: GoogleFonts.roboto(
//           fontSize: 10.sp,
//           color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//         ),
//       ),
//     );
//   }
// }



// import 'dart:ui';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/searchpage.dart';
// import 'package:socialmedia/users/Bondchat.dart';
// import 'package:socialmedia/users/profile_screen.dart';

// class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
//   CustomAppBar({super.key});

//   @override
//   Size get preferredSize => const Size.fromHeight(90); // Increased height from 70 to 90

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
// }

// class _CustomAppBarState extends State<CustomAppBar> with TickerProviderStateMixin, WidgetsBindingObserver {
//   late UserProviderall userProvider;
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;
//   late AnimationController _scaleController;
//   late Animation<double> _scaleAnimation;
//   late AnimationController _slideController;
//   late Animation<Offset> _slideAnimation;
//   bool _showAIAssistantLabel = true; // Track label visibility
//   bool _appWasInBackground = false; // Track if app was in background

//   @override
//   void initState() {
//     super.initState();

//     // Add this widget as an observer for app lifecycle changes
//     WidgetsBinding.instance.addObserver(this);

//     userProvider = Provider.of<UserProviderall>(context, listen: false);
//     userProvider.loadUserData().then((_) {
//       setState(() {}); // Refresh UI after loading data
//     });

//     // Check if this is a fresh app start and reset label visibility
//     _checkAndResetLabelOnAppStart();

//     // Original blinking animation for BondChat button
//     _blinkController = AnimationController(
//       duration: const Duration(milliseconds: 850),
//       vsync: this,
//     )..repeat(reverse: true);
//     _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);

//     // Scale animation for hanging label
//     _scaleController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     )..repeat(reverse: true);
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
//       CurvedAnimation(parent: _scaleController, curve: Curves.elasticInOut),
//     );

//     // Slide animation for hanging label
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0),
//       end: const Offset(0, 0.1),
//     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
//       // App is going to background or being killed
//       _appWasInBackground = true;
//       _markAppAsBackgrounded();
//     } else if (state == AppLifecycleState.resumed && _appWasInBackground) {
//       // App is coming back from background
//       _appWasInBackground = false;
//       _checkAndResetLabelOnAppStart();
//     }
//   }

//   // Mark that app went to background
//   Future<void> _markAppAsBackgrounded() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('app_was_backgrounded', true);
//   }

//   // Check if this is a fresh app start and reset label visibility
//   Future<void> _checkAndResetLabelOnAppStart() async {
//     final prefs = await SharedPreferences.getInstance();

//     // Check if app was previously backgrounded/killed
//     bool wasBackgrounded = prefs.getBool('app_was_backgrounded') ?? false;

//     if (wasBackgrounded) {
//       // Reset the label visibility for fresh start
//       setState(() {
//         _showAIAssistantLabel = true;
//       });
//       await prefs.setBool('show_ai_assistant_label', true);
//       await prefs.setBool('app_was_backgrounded', false);
//     } else {
//       // Load the existing state for normal navigation
//       _loadLabelVisibility();
//     }
//   }

//   // Load label visibility state from SharedPreferences
//   Future<void> _loadLabelVisibility() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _showAIAssistantLabel = prefs.getBool('show_ai_assistant_label') ?? true;
//     });
//   }

//   // Save label visibility state to SharedPreferences
//   Future<void> _saveLabelVisibility(bool show) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('show_ai_assistant_label', show);
//   }

//   // Handle BondChat button tap
//   void _onBondChatTap() {
//     setState(() {
//       _showAIAssistantLabel = false;
//     });
//     _saveLabelVisibility(false);
//     Navigator.push(context, MaterialPageRoute(builder: (context) => const BondChatScreen()));
//   }

//   @override
//   void dispose() {
//     // Remove observer when widget is disposed
//     WidgetsBinding.instance.removeObserver(this);
//     _blinkController.dispose();
//     _scaleController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProviderall>(context, listen: false);

//     return ClipRRect(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           height: 130, // Increased height from 110 to 130
//           decoration: BoxDecoration(
//             color: Theme.of(context).brightness == Brightness.dark ? Colors.black45.withOpacity(0.7) : Colors.white,
//           ),
//           child: AppBar(
//             toolbarHeight: 140.h, // Increased from 120.h to 140.h
//             automaticallyImplyLeading: false,
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             flexibleSpace: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   children: [
//                     Row(
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.only(bottom: 5.0.h),
//                           child: SizedBox(
//                               height: 40.h,
//                               child: SvgPicture.asset(
//                                 'assets/images/bondlogog.svg', // Use the SVG file path
//                                 width: 10.w, // Adjust size as needed
//                                 height: 35.h,
//                               )),
//                         ),
//                         SizedBox(width: 1.w),
//                         Text.rich(
//                           TextSpan(
//                             text: "BondBridge",
//                             style: GoogleFonts.leagueSpartan(
//                               fontSize: 28.sp, // Adjust based on your needs
//                               fontWeight: FontWeight.w800,
//                               foreground: Paint()
//                                 ..shader = const LinearGradient(
//                                   begin: Alignment.bottomLeft,
//                                   end: Alignment.topRight,
//                                   colors: [
//                                     Color(0xFF3B01B7), // Dark purple (bottom left)
//                                     Color(0xFF5E00FF), // Purple
//                                     Color(0xFFBA19EB), // Pink-purple
//                                     Color(0xFFDD0CC8), // Pink (top right)
//                                   ],
//                                   // stops: [1.0, 0.69, 0.34, 0.0]
//                                 ).createShader(
//                                   const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
//                                 ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),
//                     Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
//                                   decoration: BoxDecoration(
//                                     border: Border.all(
//                                       color: const Color(0xFF7400A5),
//                                       width: 2,
//                                     ),
//                                     borderRadius: BorderRadius.circular(15.sp),
//                                   ),
//                                   child: InkWell(
//                                     onTap: _onBondChatTap, // Use the new method
//                                     child: Row(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         FadeTransition(
//                                           opacity: _blinkAnimation,
//                                           child: Row(
//                                             children: [
//                                               SvgPicture.asset(
//                                                 'assets/icons/bondchat_star.svg',
//                                                 width: 15.w,
//                                                 height: 15.h,
//                                                 color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                                               ),
//                                               SizedBox(width: 5.w),
//                                               Text(
//                                                 'BondChat',
//                                                 style: GoogleFonts.roboto(
//                                                   fontSize: 16.sp,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 8.w),
//                                 Padding(
//                                   padding: EdgeInsets.only(top: 6.12.h),
//                                   child: IconButton(
//                                     onPressed: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(builder: (context) => const UserSearchScreen()),
//                                       );
//                                     },
//                                     icon: const Icon(Icons.search),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         // Enhanced hanging label - only show if _showAIAssistantLabel is true
//                         if (_showAIAssistantLabel)
//                           Positioned(
//                             top: 35.h,
//                             right: 50.w,
//                             child: SlideTransition(
//                               position: _slideAnimation,
//                               child: ScaleTransition(
//                                 scale: _scaleAnimation,
//                                 child: Container(
//                                   padding: EdgeInsets.symmetric(
//                                     horizontal: 8.w,
//                                     vertical: 3.h,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       colors: [
//                                         const Color(0xFF7400A5).withOpacity(0.9),
//                                         const Color(0xFFBA19EB).withOpacity(0.9),
//                                       ],
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                     ),
//                                     borderRadius: BorderRadius.circular(10.r),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: const Color(0xFF7400A5).withOpacity(0.4),
//                                         blurRadius: 6,
//                                         offset: const Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       SizedBox(width: 4.w),
//                                       // Text(
//                                       //   'Hey, I\'m your smart AI assistant,\nclick here & explore!',
//                                       //   style: GoogleFonts.roboto(
//                                       //     fontSize: 10.sp,
//                                       //     fontWeight: FontWeight.w600,
//                                       //     color: Colors.white,
//                                       //     shadows: [
//                                       //       Shadow(
//                                       //         color: Colors.black.withOpacity(0.3),
//                                       //         offset: const Offset(0, 1),
//                                       //         blurRadius: 2,
//                                       //       ),
//                                       //     ],
//                                       //   ),
//                                       // ),
//                                       Text(
//                                         '⬆️CHAT HERE⬆️',
//                                         style: GoogleFonts.roboto(
//                                           fontSize: 10.sp,
//                                           fontWeight: FontWeight.w600,
//                                           color: Colors.white,
//                                           shadows: [
//                                             Shadow(
//                                               color: Colors.black.withOpacity(0.3),
//                                               offset: const Offset(0, 1),
//                                               blurRadius: 2,
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         // Connecting line - only show if _showAIAssistantLabel is true
//                         if (_showAIAssistantLabel)
//                           Positioned(
//                             top: 32.h,
//                             right: 85.w,
//                             child: Container(
//                               width: 1.5.w,
//                               height: 6.h,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [
//                                     const Color(0xFF7400A5).withOpacity(0.6),
//                                     const Color(0xFF7400A5).withOpacity(0.2),
//                                   ],
//                                   begin: Alignment.topCenter,
//                                   end: Alignment.bottomCenter,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _BlinkingText extends StatefulWidget {
//   @override
//   __BlinkingTextState createState() => __BlinkingTextState();
// }

// class __BlinkingTextState extends State<_BlinkingText> with SingleTickerProviderStateMixin {
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _blinkController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//     _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
//   }

//   @override
//   void dispose() {
//     _blinkController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _blinkAnimation,
//       // child: Text(
//       //   'Hey, I\'m your smart AI assistant,\nclick here & explore!',
//       //   style: GoogleFonts.roboto(
//       //     fontSize: 10.sp,
//       //     color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//       //   ),
//       // ),
//       child: Text(
//         '⬆️CHAT HERE⬆️',
//         style: GoogleFonts.roboto(
//           fontSize: 10.sp,
//           color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//         ),
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/searchpage.dart';
import 'package:socialmedia/users/Bondchat.dart';
import 'package:socialmedia/users/profile_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(90); // Increased height from 70 to 90

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> with TickerProviderStateMixin, WidgetsBindingObserver {
  late UserProviderall userProvider;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _showAIAssistantLabel = true; // Track label visibility
  bool _appWasInBackground = false; // Track if app was in background

  @override
  void initState() {
    super.initState();

    // Add this widget as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {}); // Refresh UI after loading data
    });

    // Check if this is a fresh app start and reset label visibility
    _checkAndResetLabelOnAppStart();

    // Original blinking animation for BondChat button
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);

    // Scale animation for hanging label
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticInOut),
    );

    // Slide animation for hanging label
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0.1),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App is going to background or being killed
      _appWasInBackground = true;
      _markAppAsBackgrounded();
    } else if (state == AppLifecycleState.resumed && _appWasInBackground) {
      // App is coming back from background
      _appWasInBackground = false;
      _checkAndResetLabelOnAppStart();
    }
  }

  // Mark that app went to background
  Future<void> _markAppAsBackgrounded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_was_backgrounded', true);
  }

  // Check if this is a fresh app start and reset label visibility
  Future<void> _checkAndResetLabelOnAppStart() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if app was previously backgrounded/killed
    bool wasBackgrounded = prefs.getBool('app_was_backgrounded') ?? false;

    if (wasBackgrounded) {
      // Reset the label visibility for fresh start
      setState(() {
        _showAIAssistantLabel = true;
      });
      await prefs.setBool('show_ai_assistant_label', true);
      await prefs.setBool('app_was_backgrounded', false);
    } else {
      // Load the existing state for normal navigation
      _loadLabelVisibility();
    }
  }

  // Load label visibility state from SharedPreferences
  Future<void> _loadLabelVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAIAssistantLabel = prefs.getBool('show_ai_assistant_label') ?? true;
    });
  }

  // Save label visibility state to SharedPreferences
  Future<void> _saveLabelVisibility(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_ai_assistant_label', show);
  }

  // Handle BondChat button tap
  void _onBondChatTap() {
    setState(() {
      _showAIAssistantLabel = false;
    });
    _saveLabelVisibility(false);
    Navigator.push(context, MaterialPageRoute(builder: (context) => const BondChatScreen()));
  }

  @override
  void dispose() {
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    _blinkController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    // return ClipRRect(
    //   child: BackdropFilter(
    //     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    //     child: Container(
    //       height: 110, // Increased height from 110 to 130
    //       decoration: BoxDecoration(
    //         color: Theme.of(context).brightness == Brightness.dark ? Colors.black45.withOpacity(0.7) : Colors.white,
    //       ),
    //       child: AppBar(
    //         toolbarHeight: 120.h, // Increased from 120.h to 140.h
    //         automaticallyImplyLeading: false,
    //         backgroundColor: Colors.transparent,
    //         elevation: 0,
    //         flexibleSpace: SafeArea(
    //           child: Padding(
    //             padding: const EdgeInsets.symmetric(horizontal: 16),
    //             child: Row(
    //               children: [
    //                 Row(
    //                   children: [
    //                     Padding(
    //                       padding: EdgeInsets.only(bottom: 5.0.h),
    //                       child: SizedBox(
    //                           height: 40.h,
    //                           child: SvgPicture.asset(
    //                             'assets/images/bondlogog.svg', // Use the SVG file path
    //                             width: 10.w, // Adjust size as needed
    //                             height: 35.h,
    //                           )),
    //                     ),
    //                     SizedBox(width: 1.w),
    //                     Text.rich(
    //                       TextSpan(
    //                         text: "BondBridge",
    //                         style: GoogleFonts.leagueSpartan(
    //                           fontSize: 28.sp, // Adjust based on your needs
    //                           fontWeight: FontWeight.w800,
    //                           foreground: Paint()
    //                             ..shader = const LinearGradient(
    //                               begin: Alignment.bottomLeft,
    //                               end: Alignment.topRight,
    //                               colors: [
    //                                 Color(0xFF3B01B7), // Dark purple (bottom left)
    //                                 Color(0xFF5E00FF), // Purple
    //                                 Color(0xFFBA19EB), // Pink-purple
    //                                 Color(0xFFDD0CC8), // Pink (top right)
    //                               ],
    //                               // stops: [1.0, 0.69, 0.34, 0.0]
    //                             ).createShader(
    //                               const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
    //                             ),
    //                         ),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //                 const Spacer(),
    //                 Column(
    //                   crossAxisAlignment: CrossAxisAlignment.end,
    //                   mainAxisSize: MainAxisSize.min,
    //                   children: [
    //                     Row(
    //                       children: [
    //                         Container(
    //                           padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
    //                           decoration: BoxDecoration(
    //                             border: Border.all(
    //                               color: const Color(0xFF7400A5),
    //                               width: 2,
    //                             ),
    //                             borderRadius: BorderRadius.circular(15.sp),
    //                           ),
    //                           child: InkWell(
    //                             onTap: _onBondChatTap, // Use the new method
    //                             child: Row(
    //                               mainAxisAlignment: MainAxisAlignment.center,
    //                               children: [
    //                                 FadeTransition(
    //                                   opacity: _blinkAnimation,
    //                                   child: Row(
    //                                     children: [
    //                                       SvgPicture.asset(
    //                                         'assets/icons/bondchat_star.svg',
    //                                         width: 15.w,
    //                                         height: 15.h,
    //                                         color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    //                                       ),
    //                                       SizedBox(width: 5.w),
    //                                       Text(
    //                                         'BondChat',
    //                                         style: GoogleFonts.roboto(
    //                                           fontSize: 16.sp,
    //                                           fontWeight: FontWeight.bold,
    //                                           color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    //                                         ),
    //                                       ),
    //                                     ],
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                           ),
    //                         ),
    //                         SizedBox(width: 8.w),
    //                         Padding(
    //                           padding: EdgeInsets.only(top: 6.12.h),
    //                           child: IconButton(
    //                             onPressed: () {
    //                               Navigator.push(
    //                                 context,
    //                                 MaterialPageRoute(builder: (context) => const UserSearchScreen()),
    //                               );
    //                             },
    //                             icon: const Icon(Icons.search),
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                     // Enhanced hanging label - positioned below BondChat button with zero spacing
    //                     if (_showAIAssistantLabel)
    //                       Padding(
    //                         padding: EdgeInsets.only(right: 70.w), // Align with BondChat button
    //                         child: SlideTransition(
    //                           position: _slideAnimation,
    //                           child: ScaleTransition(
    //                             scale: _scaleAnimation,
    //                             child: Container(
    //                               padding: EdgeInsets.symmetric(
    //                                 horizontal: 8.w,
    //                                 vertical: 3.h,
    //                               ),
    //                               decoration: BoxDecoration(
    //                                 gradient: LinearGradient(
    //                                   colors: [
    //                                     const Color(0xFF7400A5).withOpacity(0.9),
    //                                     const Color(0xFFBA19EB).withOpacity(0.9),
    //                                   ],
    //                                   begin: Alignment.topLeft,
    //                                   end: Alignment.bottomRight,
    //                                 ),
    //                                 borderRadius: BorderRadius.circular(10.r),
    //                                 boxShadow: [
    //                                   BoxShadow(
    //                                     color: const Color(0xFF7400A5).withOpacity(0.4),
    //                                     blurRadius: 6,
    //                                     offset: const Offset(0, 2),
    //                                   ),
    //                                 ],
    //                               ),
    //                               child: Row(
    //                                 mainAxisSize: MainAxisSize.min,
    //                                 children: [
    //                                   SizedBox(width: 4.w),
    //                                   Text(
    //                                     '⬆️CHAT HERE⬆️',
    //                                     style: GoogleFonts.roboto(
    //                                       fontSize: 10.sp,
    //                                       fontWeight: FontWeight.w600,
    //                                       color: Colors.white,
    //                                       shadows: [
    //                                         Shadow(
    //                                           color: Colors.black.withOpacity(0.3),
    //                                           offset: const Offset(0, 1),
    //                                           blurRadius: 2,
    //                                         ),
    //                                       ],
    //                                     ),
    //                                   ),
    //                                 ],
    //                               ),
    //                             ),
    //                           ),
    //                         ),
    //                       ),
    //                   ],
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 110, // Increased height from 110 to 130
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black45.withOpacity(0.7) : Colors.white,
          ),
          child: AppBar(
            toolbarHeight: 120.h, // Increased from 120.h to 140.h
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 5.0.h),
                          child: SizedBox(
                              height: 40.h,
                              child: SvgPicture.asset(
                                'assets/images/bondlogog.svg', // Use the SVG file path
                                width: 10.w, // Adjust size as needed
                                height: 35.h,
                              )),
                        ),
                        SizedBox(width: 1.w),
                        Text.rich(
                          TextSpan(
                            text: "BondBridge",
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 28.sp, // Adjust based on your needs
                              fontWeight: FontWeight.w800,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: [
                                    Color(0xFF3B01B7), // Dark purple (bottom left)
                                    Color(0xFF5E00FF), // Purple
                                    Color(0xFFBA19EB), // Pink-purple
                                    Color(0xFFDD0CC8), // Pink (top right)
                                  ],
                                  // stops: [1.0, 0.69, 0.34, 0.0]
                                ).createShader(
                                  const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF7400A5),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(15.sp),
                              ),
                              child: InkWell(
                                onTap: _onBondChatTap, // Use the new method
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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

    children: [
                                    FadeTransition(
                                      opacity: _blinkAnimation,
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/bondchat_star.svg',
                                            width: 15.w,
                                            height: 15.h,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            'BondChat',
                                            style: GoogleFonts.roboto(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Padding(
                              padding: EdgeInsets.only(top: 6.12.h),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const UserSearchScreen()),
                                  );
                                },
                                icon: const Icon(Icons.search),
                              ),
                            ),
                          ],
                        ),
                        // Enhanced hanging label - positioned below BondChat button with zero spacing
                        if (_showAIAssistantLabel)
                          Transform.translate(
                            offset: Offset(0, -9.h), // Move up by 2 pixels to eliminate gap
                            child: Padding(
                              padding: EdgeInsets.only(right: 69.w), // Align with BondChat button
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF7400A5).withOpacity(0.9),
                                          const Color(0xFFBA19EB).withOpacity(0.9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7400A5).withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(width: 4.w),
                                        Text(
                                          '⇧ CHAT HERE ⇧',
                                          style: GoogleFonts.roboto(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                offset: const Offset(0, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

  }
}

class _BlinkingText extends StatefulWidget {
  @override
  __BlinkingTextState createState() => __BlinkingTextState();
}

class __BlinkingTextState extends State<_BlinkingText> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blinkAnimation,
      child: Row(
        children: [
          Text(
            '⇧ CHAT HERE ⇧',
            style: GoogleFonts.roboto(
              fontSize: 10.sp,import 'package:flutter/material.dart';
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


              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
