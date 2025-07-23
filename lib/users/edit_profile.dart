import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection_anony.dart';
import 'package:socialmedia/pages/onboarding_screens/interests.dart';
import 'package:socialmedia/users/editprofilescreens/avatar_selec.dart';
import 'package:socialmedia/users/editprofilescreens/interetsforedit.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/utils/image_cropper.dart' show CustomImageCropper;

class EditProfileScreen extends StatefulWidget {
  final String avatar;
  final List<String> selectedInterests;
  final VoidCallback? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.avatar,
    required this.selectedInterests,
    this.onProfileUpdated,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController =
      TextEditingController(); // Renamed from _emailController for clarity
  late UserProviderall userProvider;
  File? _customPhotoFile;
  String _currentAvatar = '';
  bool _isUploading = false;
  List<String> _currentInterests = [];
  bool _isLoading = false;
  bool _isRewritingBio = false; // Track rewrite loading state
  // Add this to your _EditProfileScreenState class
  String? _customPhotoPath;
  File? _selectedImageFile;
  String _selectedAvatarUrl = '';
  String _currentProfilePic = '';

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      // fetchUserData();
      setState(() {}); // Refresh UI after loading data
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchProfile();
    });

    // Initialize with the values passed to the widget
    _currentAvatar = widget.avatar;
    _currentInterests = List.from(widget.selectedInterests);
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

  Future<void> fetchProfile() async {
    if (!mounted) return; // Early return if widget is disposed

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      print('User ID or token is missing');
      return;
    }

    final Uri url = Uri.parse('${BASE_URL}api/showProfile?other=$userid');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'userid': userid,
      'token': token,
    };

    try {
      final http.Response response = await http.get(url, headers: headers);

      if (!mounted) return; // Check again before updating state

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['result'] != null &&
            responseData['result'] is List &&
            responseData['result'].isNotEmpty) {
          final userDetails = responseData['result'][0];

          // Update the controllers with fetched data
          _usernameController.text = userDetails['name'] ?? '';
          _bioController.text = userDetails['bio'] ?? '';
          _currentAvatar = userDetails['avatar'] ?? '';
          _currentProfilePic = userDetails['profilePic'] ?? '';

          // Parse interests
          if (userDetails['interests'] != null) {
            try {
              if (userDetails['interests'] is String) {
                // If interests is a JSON string
                _currentInterests =
                    List<String>.from(jsonDecode(userDetails['interests']));
              } else if (userDetails['interests'] is List) {
                // If interests is already a List
                _currentInterests = List<String>.from(userDetails['interests']);
              } else {
                _currentInterests = [];
              }
            } catch (e) {
              print('Error parsing interests: $e');
              _currentInterests = [];
            }
          } else {
            _currentInterests = [];
          }

          if (mounted) {
            setState(() {}); // Refresh the UI
          }
        } else {
          print('No user details found in the response');
        }
      } else {
        print('Failed to fetch profile. Status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching profile: $error');
    }
  }

  Future<void> _updateProfile() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    Map<String, dynamic> formData = {};

    if (_usernameController.text.isNotEmpty) {
      formData["name"] = _usernameController.text;
    }
    if (_bioController.text.isNotEmpty) {
      formData["bio"] = _bioController.text;
    }
    if (_currentAvatar.isNotEmpty) {
      formData["avatar"] = _currentAvatar;
    }

    if (_currentInterests.isNotEmpty) {
      formData["interests"] = jsonEncode(_currentInterests);
    }

    if (formData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Center(child: Text("Fill at least one field to update"))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse("${BASE_URL}api/edit-profile"),
        headers: {
          "Content-Type": "application/json",
          "token": userProvider.userToken!,
          "userId": userProvider.userId!,
        },
        body: jsonEncode(formData),
      );
      await uploadProfileData();

      if (response.statusCode == 200) {
        // Update UserProviderall with new values
        if (formData.containsKey("name")) {
          userProvider.userName = formData["name"];
        }
        if (formData.containsKey("avatar")) {
          userProvider.userProfile = formData["avatar"];
        }

        // Save updated values to SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        if (formData.containsKey("name")) {
          await prefs.setString('user_name', formData["name"]);
        }
        if (formData.containsKey("avatar")) {
          await prefs.setString('user_profile', formData["avatar"]);
        }

        // Notify listeners to update UI
        userProvider.notifyListeners();

        Fluttertoast.showToast(
          msg: "Profile updated successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Call the callback if provided
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }

        // Use pop instead of pushReplacement to go back to profile screen
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Center(child: Text("Failed to update profile"))),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update profile",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectAvatar() async {
    // Save current form values
    final String username = _usernameController.text;
    final String bio = _bioController.text;

    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AvatarSelectionScreenforsetting()));

    if (result != null && result is String) {
      setState(() {
        _currentAvatar = result;
        // Clear the custom photo if we're switching to an avatar
        _customPhotoFile = null;
        _currentProfilePic = '';
        // Restore form values
        _usernameController.text = username;
        _bioController.text = bio;
      });
    }
  }

  Future<void> _selectInterests() async {
    // Save current form values
    final String username = _usernameController.text;
    final String bio = _bioController.text;

    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Interestsforsetting(avatar: widget.avatar)));

    if (result != null && result is List<String>) {
      setState(() {
        _currentInterests = result; // Update interests with the result
        // Restore form values
        _usernameController.text = username;
        _bioController.text = bio;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors
                .darkGradient.first // Use first color in the gradient list
            : AppColors.lightGradient.first,
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.black , Colors.black]
                  : AppColors.lightGradient,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Edit Profile",
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "What Should We Call You?",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        _buildTextField("User Name", _usernameController),
                        SizedBox(height: 16.h),
                        _buildTextField("Bio", _bioController),
                        SizedBox(height: 16.h),
                        _buildButton(
                            'Choose Avatar', _selectAvatar, _currentAvatar),
                        SizedBox(height: 16.h),
                        _buildButtonForInterest('Choose Interests',
                            _selectInterests, _currentInterests),
                        SizedBox(height: 20.h),
                        Padding(
                          padding: EdgeInsets.only(bottom: 40.h),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7400A5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 100, vertical: 16),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.black)
                                  : Text(
                                      "Save",
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {IconData? icon}) {
    bool isBio = hint.toLowerCase() == "bio";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: GoogleFonts.roboto(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
          maxLines: isBio ? 5 : 1, // Multiple lines for bio
          maxLength: isBio ? 150 : null, // Character limit for bio
          keyboardType: isBio ? TextInputType.multiline : TextInputType.text,
          toolbarOptions: ToolbarOptions(
            copy: true,
            cut: true,
            paste: true,
            selectAll: true,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(isBio ? 150 : null),
          ],
          textInputAction: isBio ? TextInputAction.done : TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.roboto(color: Colors.grey),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            counterText: isBio ? "" : null, // Hide default counter for bio
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.sp),
              borderSide: const BorderSide(color: Color(0xFF7400A5)),
            ),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          ),
        ),
        if (isBio) ...[
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _isRewritingBio ? null : _rewriteBioWithBondChat,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(54.r),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFF1E1E1E)
                        : Colors.grey[100],
                    border: Border.all(color: Color(0xFF7400A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 4),
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
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            Color(0xFF3B01B7), // Dark purple
                            Color(0xFF5E00FF), // Purple
                            Color(0xFFBA19EB), // Pink-purple
                            Color(0xFFDD0CC8), // Pink
                          ],
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: Text(
                          'BondChat',
                          style: GoogleFonts.roboto(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Will be replaced by gradient
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
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length}/150',
                    style: GoogleFonts.roboto(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

// 2. Modified _buildButton method
  Widget _buildButton(String text, VoidCallback onPressed, String imageUrl) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with current image description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile Picture",
                      style: GoogleFonts.roboto(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Choose an avatar or upload your own profile picture",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Large preview of selected image
          if (_currentAvatar.isNotEmpty || _customPhotoFile != null || _currentProfilePic.isNotEmpty)
            Center(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  CircleAvatar(
                    radius: 75.sp,
                    backgroundImage: _customPhotoFile != null
                        ? FileImage(_customPhotoFile!)
                        : _currentAvatar.isNotEmpty
                            ? NetworkImage(_currentAvatar) as ImageProvider
                            : NetworkImage(_currentProfilePic) as ImageProvider,
                  ),
                  _buildCloseButton(() {
                    setState(() {
                      if (_customPhotoFile != null) {
                        _customPhotoFile = null;
                      } else if (_currentProfilePic.isNotEmpty) {
                        _currentProfilePic = '';
                      } else {
                        _currentAvatar = '';
                      }
                    });
                  }, true),
                ],
              ),
            ),
          SizedBox(height: 16.h),

          // Tab Bar
          Container(
            height: 45.h,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Color(0xFF7400A5),
                borderRadius: BorderRadius.circular(25.0),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              tabs: [Tab(text: "Avatar"), Tab(text: "Custom Photo")],
            ),
          ),

          // Tab Content
          Container(
            height: 150.h, // Reduced height since we don't show previews here
            child: TabBarView(
              children: [
                // Avatar Tab - Only shows option to choose
                _buildAvatarTab(imageUrl, onPressed),
                _buildCustomPhotoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 3. Simplified Avatar Tab Content
  Widget _buildAvatarTab(String imageUrl, VoidCallback onPressed) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 60, color: Colors.grey),
            Text("Choose Avatar", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

// 4. Simplified Custom Photo Tab Content
  Widget _buildCustomPhotoTab() {
    return Center(
      child: GestureDetector(
        onTap: () => _pickCustomPhoto(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 60, color: Colors.grey),
            Text("Upload Custom Photo",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

// 5. Image Handling Logic
  Future<void> _pickCustomPhoto(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      builder: (bc) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(
                    bc, await _picker.pickImage(source: ImageSource.camera));
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose From Gallery'),
              onTap: () async {
                Navigator.pop(
                    bc, await _picker.pickImage(source: ImageSource.gallery));
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null && mounted) {
      final File imageFile = File(pickedFile.path);

      // Show the custom image cropper
      final File? croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CustomImageCropper(
            imageFile: imageFile,
            onCropComplete: (File croppedFile) {
              // This callback is called before navigation
              if (mounted) {
                setState(() {
                  _customPhotoFile = croppedFile;
                  _currentAvatar = ''; // Clear avatar selection
                  _currentProfilePic = ''; // Clear current profile pic
                });
              }
            },
          ),
        ),
      );

      // This is a safety check, but the state should already be updated by the callback
      if (croppedFile != null && mounted) {
        setState(() {
          _customPhotoFile = croppedFile;
          _currentAvatar = ''; // Clear avatar selection
          _currentProfilePic = ''; // Clear current profile pic
        });
      }
    }
  }

  Future<void> uploadProfileData() async {
    // Get required data
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('user_token') ?? '';
    final name = _usernameController.text;

    try {
      if (_customPhotoFile != null) {
        await uploadImage(_customPhotoFile!, userId, token, name);
      } else if (_currentAvatar.isNotEmpty) {
        await _updateAvatarOnServer(_currentAvatar, userId, token, name);
      }

      // Navigate after successful update
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => user_profile()),
      );
    } catch (e) {
      print('Error updating profile: $e');
      // Show error message
    }
  }

  Future<void> uploadImage(
      File imageFile, String userId, String token, String name) async {
    var uri = Uri.parse("${BASE_URL}api/edit-profile");
    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll({
        'userId': userId,
        'token': token,
      })
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path))
      ..fields['name'] = name;

    var response = await request.send();
    var responseString = await response.stream.bytesToString();

    print("Status Code: ${response.statusCode}");
    print("Response: $responseString");

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image');
    }
  }

// 5. Add avatar update method
  Future<void> _updateAvatarOnServer(String avatarUrl, String userId, String token, String name) async {
    final response = await http.put(
      Uri.parse("${BASE_URL}api/edit-profile"),
      headers: {
        'userId': userId,
        'token': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'avatar': avatarUrl,
        'name': name,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update avatar');
    }
  }

// 6. Update Profile Method

// Helper Widget
  Widget _buildCloseButton(VoidCallback onPressed, bool isCustomPhoto) {
    return Positioned(
      top: 0,
      right: 0,
      child: GestureDetector(
        onTap: () async {
          // Show confirmation dialog
          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black 
                    : Colors.white,
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
                      'Delete Profile Picture',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  'Are You Sure You Want To\nDelete Your Profile Picture?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
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
                        Navigator.of(context).pop(true); // Confirm deletion
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
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          if (!isCustomPhoto) confirm = false;
          if (confirm == true) {
            await deleteProfilePicture();
            onPressed(); // Call the original onPressed callback
          }
        },
        child: CircleAvatar(
          radius: 16.sp,
          backgroundColor: Color(0xFF7400A5),
          child: Icon(Icons.close, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> deleteProfilePicture() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      print('User ID or token is missing');
      return;
    }

    final Uri url = Uri.parse('${BASE_URL}api/profile-picture');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'userid': userid,
      'token': token,
    };

    try {
      final http.Response response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _currentAvatar = '';
          _customPhotoFile = null;
        });

        // Update the UserProvider
        final userProvider =
            Provider.of<UserProviderall>(context, listen: false);
        userProvider.userProfile = '';
        await prefs.remove('user_profile');

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Profile picture deleted successfully")),
        // );
      } else {
        throw Exception('Failed to delete profile picture');
      }
    } catch (error) {
      print('Error deleting profile picture: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete profile picture")),
      );
    }
  }

  Widget _buildButtonForInterest(
      String text, VoidCallback onPressed, List<String> selectedInterests) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.sp),
              side: const BorderSide(color: Color(0xFF7400A5)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        if (selectedInterests.isNotEmpty) ...[
          Container(
            constraints: BoxConstraints(
              maxHeight: 150.h, // Limit the height of the interests container
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: selectedInterests.map((interest) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(color: Colors.deepPurpleAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          interest,
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 6.h),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedInterests.remove(interest);
                            });
                          },
                          child: const Icon(Icons.close,
                              color: Colors.deepPurpleAccent, size: 18),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }
}
