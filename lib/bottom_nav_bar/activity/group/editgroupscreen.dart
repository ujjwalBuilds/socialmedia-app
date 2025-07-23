import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/detailed_chat_page.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:convert';
import 'package:socialmedia/bottom_nav_bar/activity/group/see_participants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditGroupScreen extends StatefulWidget {
  final String chatRoomId;
  final VoidCallback? onGroupUpdated;

  const EditGroupScreen({
    super.key,
    required this.chatRoomId,
    this.onGroupUpdated,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _existingProfilePic;

  List<String> selectedInterests = [];
  final List<String> availableInterests = [
    'Memes',
    'Food & Culinary',
    'Pop Culture',
    'Gaming',
    'Health',
    'Outdoor Adventures',
    'Music',
    'Movies',
    'TV Shows',
    'Pets',
    'Fitness',
    'Travel',
    'Photography',
    'Technology',
    'DIY',
    'Fashion',
    'Literature',
    'Comedy',
    'Social Activism',
    'Social Media',
    'Craft Mixology',
    'Podcasts',
    'Cultural Arts',
    'History',
    'Science',
    'Auto Enthusiasts',
    'Meditation',
    'Virtual Reality',
    'Dance',
    'Board Games',
    'Wellness',
    'Trivia',
    'Content Creation',
    'Graphic Arts',
    'Anime',
    'Sports',
    'Stand-Up',
    'Crafts',
    'Exploration',
    'Concerts',
    'Musicians',
    'Animal Lovers',
    'Visual Arts',
    'Animation',
    'Style',
    'Basketball',
    'Football',
    'Hockey',
    'Boxing',
    'MMA',
    'Wrestling',
    'Baseball',
    'Golf',
    'Tennis',
    'Track & Field',
    'Gadgets',
    'Mathematics',
    'Physics',
    'Outer Space',
    'Religious',
    'Culture'
  ];

  bool showAllInterests = false; // Toggle to show all interests

  bool isLoading = false;

  bool _isRewritingBio = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final String? userId = userProvider.userId;
      final String? token = userProvider.userToken;

      if (userId == null || token == null) {
        throw Exception("User credentials not found.");
      }

      final response = await http.get(
        Uri.parse(
            "${BASE_URL}api/get-chatroom-details?chatRoomId=${widget.chatRoomId}"),
        headers: {
          'userId': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chatRoom = data["chatRoom"];

        setState(() {
          _groupNameController.text = chatRoom["groupName"] ?? "";
          _bioController.text = chatRoom["bio"] ?? "";
          _existingProfilePic = chatRoom["profileUrl"];
        });
      }
    } catch (error) {
      print("Error fetching group details: $error");
    }
  }

  /// Function to Pick Image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  /// Function to Update Group Info
  Future<void> _updateGroup() async {
    if (_bioController.text.isEmpty &&
        _groupNameController.text.isEmpty &&
        _profileImage == null) {
      Fluttertoast.showToast(
        msg: "No changes to update!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.pop(context);
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final String? userId = userProvider.userId;
      final String? token = userProvider.userToken;

      if (userId == null || token == null) {
        throw Exception("User credentials not found.");
      }

      print('Starting group update...');
      print('ChatRoomId: ${widget.chatRoomId}');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("${BASE_URL}api/edit-group"),
      );

      // Add headers
      request.headers.addAll({
        'userid': userId,
        'token': token,
      });

      // Add fields
      request.fields['chatRoomId'] = widget.chatRoomId;
      if (_groupNameController.text.isNotEmpty) {
        request.fields['groupName'] = _groupNameController.text;
      }
      if (_bioController.text.isNotEmpty) {
        request.fields['bio'] = _bioController.text;
      }

      print('Request fields:');
      print(request.fields);

      // Handle image upload
      if (_profileImage != null) {
        try {
          print('Preparing to upload image...');
          print('Image path: ${_profileImage!.path}');
          print('Image exists: ${await _profileImage!.exists()}');
          print('Image size: ${await _profileImage!.length()} bytes');

          final file = await http.MultipartFile.fromPath(
              'image', // Changed from 'profilePic' to 'image'
              _profileImage!.path,
              filename:
                  'group_profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

          request.files.add(file);
          print('Image file added to request:');
          print('Field name: ${file.field}');
          print('Filename: ${file.filename}');
          print('Content-Type: ${file.contentType}');
          print('Length: ${file.length}');
        } catch (e) {
          print('Error preparing image: $e');
        }
      }

      print('Sending request to server...');
      final streamedResponse = await request.send();
      print('Response status: ${streamedResponse.statusCode}');

      final responseData = await streamedResponse.stream.bytesToString();
      print('Response body: $responseData');

      if (streamedResponse.statusCode == 200) {
        final decodedResponse = json.decode(responseData);
        print('Decoded response: $decodedResponse');

        Fluttertoast.showToast(
          msg: "Group updated successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        widget.onGroupUpdated?.call();
        Navigator.pop(context);
      } else {
        print('Error status code: ${streamedResponse.statusCode}');
        print('Error response: $responseData');
        throw Exception(
            "Failed to update group: ${streamedResponse.statusCode}");
      }
    } catch (error) {
      print("Error updating group: $error");
      print("Stack trace:");
      print(StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text("Failed to update group: $error")),
        ),
      );
      Navigator.pop(context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add method to handle group deletion
  Future<void> _deleteGroup() async {
    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);

      // Show confirmation dialog
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Delete Group'),
              content: Text('Are you sure you want to delete this group?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-group'),
        headers: {
          'userid': userProvider.userId!,
          'token': userProvider.userToken!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'chatRoomId': widget.chatRoomId,
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Group deleted successfully!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => BottomNavBarScreen()),
          (route) => false,
        );
      } else {
        throw Exception('Failed to delete group');
      }
    } catch (error) {
      print('Error deleting group: $error');
      Fluttertoast.showToast(msg: "Failed to delete group");
    }
  }

  void _rewriteBioWithBondChat() async {
    if (_bioController.text.isEmpty) return;

    // Select all text
    _bioController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _bioController.text.length,
    );

    setState(() => _isRewritingBio = true); // Show loading

    try {
      // Make API Call
      final response = await http.post(
        Uri.parse("${BASE_URL}api/reWriteWithBond"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"caption": _bioController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bioController.text = data["rewritten"]; // Update controller text
        });
      } else {
        print("Failed to fetch rewritten text");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to rewrite bio. Please try again.")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    } finally {
      setState(() => _isRewritingBio = false); // Hide loading
    }
  }

  @override
  Widget build(BuildContext context) {
    int displayedInterestCount =
        showAllInterests ? availableInterests.length : 15;
    return WillPopScope(
      onWillPop: () async {
        widget.onGroupUpdated?.call();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Edit Group",
              style: GoogleFonts.roboto(fontSize: 18),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                widget.onGroupUpdated?.call();
                Navigator.pop(context);
              },
            ),
            actions: [
              // Add delete button in AppBar
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteGroup,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF7400A5),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : _existingProfilePic != null &&
                                    _existingProfilePic!.isNotEmpty
                                ? NetworkImage(_existingProfilePic!)
                                : null,
                        child: (_profileImage == null && 
                                (_existingProfilePic == null || _existingProfilePic!.isEmpty))
                            ? Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: SvgPicture.asset(
                                  'assets/icons/group.svg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : null,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, size: 18, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 7.h),
                FittedBox(
                  child: Text(
                    "Upload Group Image",
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: "Group Name",
                    labelStyle: GoogleFonts.roboto(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: "About Group",
                    labelStyle: GoogleFonts.roboto(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(54.r),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey[100],
                        border: Border.all(color: const Color(0xFF7400A5)),
                      ),
                      child: GestureDetector(
                        onTap: _isRewritingBio ? null : _rewriteBioWithBondChat,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 4.w),
                            _isRewritingBio
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF7400A5),
                                    ),
                                  )
                                : Text(
                                    'Re-write with ',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? AppColors.darkText
                                          : AppColors.lightText,
                                    ),
                                  ),
                            if (!_isRewritingBio) ...[
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
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${_bioController.text.length}/150',
                      style: GoogleFonts.roboto(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Group Interests",
                    style: GoogleFonts.roboto(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap for displaying interests
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 12.h,
                        children: availableInterests
                            .take(displayedInterestCount)
                            .map((interest) {
                          final isSelected =
                              selectedInterests.contains(interest);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedInterests.remove(interest);
                                } else {
                                  selectedInterests.add(interest);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(0xFF7400A5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isSelected
                                        ? Color(0xFF7400A5)
                                        : Colors.grey.shade400),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    interest,
                                    style: GoogleFonts.roboto(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade800,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    isSelected ? Icons.close : Icons.add,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 20.h),

                      // Explore More Button
                      if (!showAllInterests)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showAllInterests = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                            side: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Color(0xFF7400A5)
                                  : Color(0xFF7400A5),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            "Explore More +",
                            style: GoogleFonts.roboto(
                              fontSize: 14.sp,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Color(0xFF7400A5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _updateGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7400A5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Continue",
                          style: GoogleFonts.roboto(
                              fontSize: 16, color: Colors.white),
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
