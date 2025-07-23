import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/custom_dropdown.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/user_apis/post_api.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PostScreen extends StatefulWidget {
  final String? communityId;

  const PostScreen({super.key, this.communityId});
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "";

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage; // To store the selected image
  String? userid;
  String? token;
  String? username;
  List<XFile> _selectedImages = [];
  late UserProviderall userProvider;
  bool _isLoadingbond = false; // Loading state
  int _characterCount = 0;
  bool _isLoading = false; // To manage the loading state
  double _keyboardHeight = 0.0;
  bool _isAnonymous = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChange);
    userProvider = Provider.of<UserProviderall>(context, listen: false);

    // Debug print to check if profilePic is available
    print("Current profilePic value: ${userProvider.profilePic}");

    // Ensure user data is loaded
    userProvider.loadUserData().then((_) {
      print("After loading, profilePic value: ${userProvider.profilePic}");
      setState(() {}); // Refresh UI after loading data
    });

    FilePicker.platform;
    getuseridandtoken();

    _speech = stt.SpeechToText();
  }

  Future<void> _startListening() async {
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
            _controller.text = result.recognizedWords;
            _characterCount = _controller.text.length;
          });

          // Send message only when speech recognition is complete
          if (result.finalResult) {
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

  bool isVideo(XFile file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Keyboard is open
    } else {
      // Keyboard is closed
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
    _speech.stop();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _keyboardHeight = bottomInset;
    });
  }

  void _selectAndRewriteText() async {
    if (_controller.text.isEmpty) return;

    // Select all text
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    setState(() => _isLoading = true); // Show loading

    try {
      // Make API Call
      final response = await http.post(
        Uri.parse("${BASE_URL}api/reWriteWithBond"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"caption": _controller.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _controller.text = data["rewritten"]; // Update controller text
        });
      } else {
        print("Failed to fetch rewritten text");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false); // Hide loading
    }
  }

  void _toggleAnonymous() {
    setState(() {
      _isAnonymous = !_isAnonymous;
    });
  }

  Future<void> _postToCommunity() async {
    setState(() => _isLoading = true);

    await submitCommunityPost(
      context: context,
      mediaFiles: _selectedImages.map((xfile) => File(xfile.path)).toList(),
      userid: userid!,
      token: token!,
      content: _controller.text,
      communityId: widget.communityId!,
      isAnonymous: _isAnonymous,
    );
  }

  void _post() async {
    setState(() => _isLoading = true);

    try {
      if (widget.communityId == null) {
        log("Post to Explore page");
        await submitPost(
          context: context,
          mediaFiles: _selectedImages.map((xfile) => File(xfile.path)).toList(),
          userid: userid!,
          token: token!,
          content: _controller.text,
        );
      } else {
        log("Post to Community page");
        await _postToCommunity();
        return;
      }

      if (widget.communityId == null) {
        Navigator.pop(context);
      } else {
        // Refresh the posts in Explore page
        final postsProvider = Provider.of<PostsProvider>(context, listen: false);
        await postsProvider.fetchPosts(userid!, token!, forceRefresh: true);

        // Navigate back to Explore page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMedia() async {
    try {
      // Show bottom sheet with options
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 300.h,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            child: Column(
              children: [
                // First ListTile styled like OutlinedButton
                Padding(
                  padding: EdgeInsets.all(16.0.h),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0xFF7400A5),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(15.sp),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.photo,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      title: Text(
                        'Photos',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final List<XFile> pickedImages = await _picker.pickMultiImage();
                        if (pickedImages.isNotEmpty) {
                          setState(() {
                            _selectedImages.addAll(pickedImages);
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 5.h), // Add spacing between tiles

                // Second ListTile styled like OutlinedButton
                Padding(
                  padding: EdgeInsets.all(16.0.h),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0xFF7400A5),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(15.sp),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.video_library,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      title: Text(
                        'Videos',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? videoFile = await ImagePicker().pickVideo(
                          source: ImageSource.gallery,
                        );

                        if (videoFile != null) {
                          final controller = VideoPlayerController.file(File(videoFile.path));
                          await controller.initialize();
                          final duration = controller.value.duration.inSeconds;
                          await controller.dispose();

                          if (duration <= 60) {
                            setState(() {
                              _selectedImages.add(videoFile);
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Videos longer than 1 minute are not allowed.")),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stack) {
      debugPrint('❌ Error picking media: $e');
      debugPrint('🪵 Stack trace: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick media: $e")),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> getuseridandtoken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userid = prefs.getString('user_id');
      token = prefs.getString('user_token');
    }); // Retrieve the 'username' key
  }

  Future<File?> _compressImage(File file) async {
    try {
      // Get the image size
      final fileSize = await file.length();
      // If file is already small enough (e.g., less than 1MB), return as is
      if (fileSize < 1024 * 1024) {
        return file;
      }

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        file.path + '_compressed.jpg',
        quality: 70, // Adjust quality as needed
        minWidth: 1080, // Adjust width as needed
        minHeight: 1080, // Adjust height as needed
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // onWillPop: () async {
      //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
      //   return false;
      // },
      onWillPop: () async {
        // Check if there's unsaved content
        if (_controller.text.isNotEmpty || _selectedImages.isNotEmpty) {
          // Show confirmation dialog
          bool? shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(color: Color(0xFF7400A5), width: 1.0), // Add this line for the border
                ),
                title: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/bondlogog.svg', // Use the SVG file path
                      width: 25.w, // Adjust size as needed
                      height: 50.h,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Discard Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'You have unsaved changes,\nDo you want to discard?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // Cancel
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7400A5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Discard',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            },
          );

          if (shouldDiscard == true) {
            // Clear the state before popping
            _controller.clear();
            _selectedImages.clear();
            Navigator.of(context).pop(true); // Explicitly pop with result
          }
          return shouldDiscard ?? false; // Prevent default back behavior
        } else {
          // No unsaved changes, navigate normally
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
          // return false;
          Navigator.of(context).pop(true);
          return true;
        }
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: true, // Ensure keyboard adjusts the layout
          // SafeArea will ensure layout respects system insets
          body: SafeArea(
            // Use bottom: false to ensure content can extend to the bottom edge
            bottom: false,
            child: Stack(
              children: [
                // Gradient Background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: Theme.of(context).brightness == Brightness.dark ? [Colors.black, Colors.black] : AppColors.lightGradient),
                  ),
                ),
                // Main Content with Footer Space
                Column(
                  children: [
                    // Top Bar
                    Container(
                      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10, // Reduced from 50 since we're using SafeArea
                          bottom: 18,
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () async {
                                // Check if there's unsaved content
                                if (_controller.text.isNotEmpty || _selectedImages.isNotEmpty) {
                                  // Show confirmation dialog
                                  bool? shouldDiscard = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16.0),
                                          side: BorderSide(color: Color(0xFF7400A5), width: 1.0),
                                        ),
                                        title: Column(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/images/bondlogog.svg',
                                              width: 25.w,
                                              height: 50.h,
                                            ),
                                            SizedBox(height: 12.h),
                                            Text(
                                              'Discard Post',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          'You have unsaved changes,\nDo you want to discard?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                            fontSize: 14,
                                          ),
                                        ),
                                        actionsAlignment: MainAxisAlignment.center,
                                        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        actions: [
                                          SizedBox(
                                            width: 120,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(false); // Cancel
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black87,
                                                elevation: 0,
                                                side: BorderSide(color: Colors.grey[300]!),
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                'Cancel',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          SizedBox(
                                            width: 120,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF7400A5),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                'Discard',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDiscard == true) {
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
                                  }
                                } else {
                                  // No unsaved changes, navigate directly
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
                                }
                              },
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              child: userProvider.profilePic != null
                                  ? ClipOval(
                                      child: Image.network(
                                        userProvider.profilePic!,
                                        fit: BoxFit.cover,
                                        width: 32,
                                        height: 32,
                                        errorBuilder: (context, error, stackTrace) {
                                          print("Error loading profile image: $error");
                                          return Icon(Icons.person, color: Colors.grey[600]);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.person, color: Colors.grey[600]),
                            ),
                            SizedBox(width: 8),
                            FittedBox(
                              child: Text(
                                'Make a Post',
                                style: GoogleFonts.roboto(
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: InkWell(
                                onTap: () async {
                                  if (userid == null || token == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Center(child: Text('Something went wrong'))),
                                    );
                                    return;
                                  }
                                  ;
                                  if (_controller.text.isEmpty && _selectedImages.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Please add a caption or image'),
                                      ),
                                    );
                                    return;
                                  }
                                  ;
                                  _post();
                                },
                                child: Container(
                                  height: 35.h,
                                  width: 65.w,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF7400A5),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? LoadingAnimationWidget.waveDots(
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : Text(
                                            'Post',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.darkText,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    // Text Input Area with space for bottom buttons
                    Expanded(
                      child: Column(
                        children: [
                          widget.communityId != null
                              ? SizedBox(
                                  width: double.infinity,
                                  child: CustomDropdown(
                                    onSelectionChanged: (isAnonymous) {
                                      _toggleAnonymous();
                                    },
                                  ))
                              : const SizedBox.shrink(),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      autofocus: true,
                                      maxLength: 150, // Add this line to limit to 150 characters
                                      maxLengthEnforcement: MaxLengthEnforcement.enforced, // Add this to enforce the limit
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(150),
                                      ],
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                      ),
                                      maxLines: null,
                                      decoration: InputDecoration(
                                        hintText: 'What\'s On Your Mind...',
                                        hintStyle: GoogleFonts.roboto(
                                          color: Colors.grey[600],
                                          fontSize: 14.sp,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(16),
                                        counterText: '$_characterCount/150',
                                      ),
                                      onChanged: (text) {
                                        setState(() {
                                          _characterCount = text.length;
                                        });
                                      }),

                                  if (_selectedImages.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                        children: [
                                          CarouselSlider(
                                            options: CarouselOptions(
                                              height: MediaQuery.of(context).size.height * 0.40,
                                              viewportFraction: 1.0,
                                              enableInfiniteScroll: false,
                                              autoPlay: false,
                                            ),
                                            items: _selectedImages.asMap().entries.map((entry) {
                                              final index = entry.key;
                                              final file = entry.value;

                                              return Builder(
                                                builder: (BuildContext context) {
                                                  if (isVideo(file)) {
                                                    // Display video with VideoPlayer
                                                    return VideoPlayerWidget(
                                                      videoFile: file,
                                                      onRemove: () => _removeImage(index),
                                                    );
                                                  } else {
                                                    // Display image
                                                    return Stack(
                                                      children: [
                                                        Container(
                                                          width: double.infinity,
                                                          height: MediaQuery.of(context).size.height * 0.40,
                                                          child: Image.file(
                                                            File(file.path),
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                        Positioned(
                                                          right: 10,
                                                          top: 10,
                                                          child: GestureDetector(
                                                            onTap: () => _removeImage(index),
                                                            child: Container(
                                                              padding: EdgeInsets.all(4),
                                                              decoration: BoxDecoration(
                                                                color: Colors.black.withOpacity(0.5),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: Icon(Icons.close, color: Colors.white),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                },
                                              );
                                            }).toList(),
                                          ),
                                          // Image count indicator
                                          if (_selectedImages.length > 1)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.6),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '${_selectedImages.length} Photos',
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.white,
                                                        fontSize: 12.sp,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                  // Display Selected Image (if any)
                                  if (_selectedImage != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Container(
                                        height: MediaQuery.of(context).size.height * 0.40,
                                        width: MediaQuery.of(context).size.width,
                                        child: Image.file(
                                          File(_selectedImage!.path),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom Action Buttons - Fixed at bottom
                          Container(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom > 0
                                  ? MediaQuery.of(context).padding.bottom + 1.h
                                  : 20.h, // Add extra padding for navigation bar
                              top: 10.h,
                              left: 16.w,
                              right: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[100],
                              border: Border(
                                top: BorderSide(
                                  color:
                                      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : (Colors.grey[200] ?? Colors.grey),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(54.r),
                                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                                    border: Border.all(color: const Color(0xFF7400A5)),
                                  ),
                                  child: GestureDetector(
                                    onTap: _isLoading ? null : _selectAndRewriteText,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Re-write with ',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                          ),
                                        ),
                                        ShaderMask(
                                          blendMode: BlendMode.srcIn,
                                          shaderCallback: (bounds) => const LinearGradient(
                                            begin: Alignment.bottomLeft,
                                            end: Alignment.topRight,
                                            colors: [
                                              Color(0xFF3B01B7), // Dark purple (bottom left)
                                              Color(0xFF5E00FF), // Purple
                                              Color(0xFFBA19EB), // Pink-purple
                                              Color(0xFFDD0CC8), // Pink (top right)
                                            ],
                                          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                          child: Text(
                                            'BondChat',
                                            style: GoogleFonts.roboto(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white, // This color will be replaced by the gradient
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5.w),
                                        SvgPicture.asset(
                                          'assets/icons/bondchat_star.svg',
                                          width: 15.w,
                                          height: 15.h,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  iconSize: 24.sp,
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: _isListening
                                        ? const Color(0xFF7400A5) // Purple when active
                                        : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                                  ),
                                  onPressed: () {
                                    if (_isListening) {
                                      _stopListening();
                                    } else {
                                      _startListening();
                                    }
                                  },
                                ),
                                IconButton(
                                  iconSize: 24.sp,
                                  icon: Icon(
                                    Icons.perm_media_outlined,
                                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                  onPressed: _pickMedia,
                                ),
                                IconButton(
                                  iconSize: 24.sp,
                                  icon: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                  onPressed: () async {
                                    final XFile? image = await _picker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 70, // Add image quality parameter to reduce file size
                                    );
                                    if (image != null) {
                                      // Compress the image before adding to list
                                      final File? compressedFile = await _compressImage(File(image.path));
                                      if (compressedFile != null) {
                                        setState(() {
                                          _selectedImages.add(XFile(compressedFile.path));
                                        });
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final XFile videoFile;
  final VoidCallback onRemove;

  const VideoPlayerWidget({
    super.key,
    required this.videoFile,
    required this.onRemove,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _videoController;
  bool _isPlaying = false;
  double? _aspectRatio;

  StreamSubscription<int?>? _widthSubscription;
  StreamSubscription<int?>? _heightSubscription;
  StreamSubscription<bool>? _playingSubscription;

  int? _videoWidth;
  int? _videoHeight;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _player.open(Media(widget.videoFile.path), play: false);

    _playingSubscription = _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });

    _widthSubscription = _player.stream.width.listen((width) {
      if (mounted && width != null) {
        setState(() {
          _videoWidth = width;
          _updateAspectRatio();
        });
      }
    });

    _heightSubscription = _player.stream.height.listen((height) {
      if (mounted && height != null) {
        setState(() {
          _videoHeight = height;
          _updateAspectRatio();
        });
      }
    });
  }

  void _updateAspectRatio() {
    if (_videoWidth != null && _videoHeight != null && _videoHeight! > 0) {
      if (mounted) {
        setState(() {
          _aspectRatio = _videoWidth! / _videoHeight!;
        });
      }
    }
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _widthSubscription?.cancel();
    _heightSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: _aspectRatio == null || _aspectRatio! <= 0
              ? const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(child: CircularProgressIndicator()),
                )
              : AspectRatio(
                  aspectRatio: _aspectRatio!,
                  child: Video(controller: _videoController),
                ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: GestureDetector(
            onTap: widget.onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        Center(
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 50,
            ),
            onPressed: () {
              _player.playOrPause();
            },
          ),
        ),
      ],
    );
  }
}
