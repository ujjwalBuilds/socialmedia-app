import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/user_apis/post_api.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:provider/provider.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String currentCaption;
  final String imageUrl;
  final String? communityId;
  final bool? isAnonymous;

  const EditPostScreen({
    Key? key,
    required this.postId,
    required this.currentCaption,
    required this.imageUrl,
    this.isAnonymous,
    this.communityId,
  }) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _captionController;
  bool _isLoading = false;
  String? userid;
  String? token;

  @override
  void initState() {
    super.initState();
    getuseridandtoken();
    _captionController = TextEditingController(text: widget.currentCaption);
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
        _captionController.selection = TextSelection.fromPosition(
          TextPosition(offset: _captionController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userid = prefs.getString('user_id');
      final String? token = prefs.getString('user_token');

      if (userid == null || token == null) {
        throw Exception('User ID or token is missing');
      }

      final response = await http.put(
        Uri.parse('${BASE_URL}api/edit-post'),
        headers: {
          'userid': userid,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': _captionController.text,
          'post_id': widget.postId,
          // 'content_type': 'image',
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception('Failed to update post');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getuseridandtoken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userid = prefs.getString('user_id');
      token = prefs.getString('user_token');
    }); // Retrieve the 'username' key
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post',
          style: GoogleFonts.roboto(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
                ? Container(
                    width: 70,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(0xFF7400A5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      if (widget.communityId == null) {
                        _updatePost();
                      } else {
                        await submitCommunityPost(
                          context: context,
                          mediaFiles: [],
                          userid: userid!,
                          token: token!,
                          content: _captionController.text,
                          communityId: widget.communityId!,
                          isAnonymous: widget.isAnonymous ?? false,
                          postId : widget.postId,
                          isEdit: true
                        ).then((value) {
                          Navigator.pop(navigatorKey.currentContext!);  
                        });
                      }
                      

                    
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7400A5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              // Row(
              //   children: [
              //     // This could be replaced with the actual user profile image
              //     CircleAvatar(
              //       radius: 20,
              //       backgroundColor: Colors.grey.shade300,
              //       backgroundImage: Provider.of<UserProviderall>(context, listen: false).profilePic != null
              //           ? NetworkImage(Provider.of<UserProviderall>(context, listen: false).profilePic!)
              //           : null,
              //       child: Provider.of<UserProviderall>(context, listen: false).profilePic == null
              //           ? Icon(Icons.person, color: Colors.grey.shade600)
              //           : null,
              //     ),
              //     SizedBox(width: 10),
              //     Text(
              //       Provider.of<UserProviderall>(context, listen: false).name ?? 'User',
              //       style: GoogleFonts.roboto(
              //         fontWeight: FontWeight.w500,
              //         color: isDarkMode ? Colors.white : Colors.black,
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 12),
              
              // Caption TextField that looks like regular text
              TextField(
                controller: _captionController,
                maxLines: null,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                autofocus: true,
              ),
              
              SizedBox(height: 12),
              
              // Only show image if URL is provided
              if (widget.imageUrl.isNotEmpty)
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Center(
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
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
}
