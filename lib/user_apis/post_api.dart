import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:http_parser/http_parser.dart';

Future<void> submitPost({
  required BuildContext context,
  required List<File> mediaFiles,
  required String userid,
  required String token,
  required String content,
}) async {
  // 1. Check total size of all media files
  int totalBytes = 0;
  for (final file in mediaFiles) {
    totalBytes += await file.length();
  }
  const int maxBytes = 50 * 1024 * 1024; // 50MB

  if (totalBytes > maxBytes) {
    // 2. Show custom SnackBar and return early
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maximum post media size is 50mb')),
    );
    return;
  }

  const String url = '${BASE_URL}api/post';
  final request = http.MultipartRequest('POST', Uri.parse(url))
    ..headers.addAll({
      'userid': userid,
      'token': token,
    })
    ..fields.addAll({
      'privacy': '1',
      'whoCanComment': '1',
      'content': content,
    });

  try {
    for (final file in mediaFiles) {
      final fileExt = file.path.split('.').last.toLowerCase();
      final isVideo = [
        'mp4',
        'mov',
        'avi'
      ].contains(fileExt);

      final part = await http.MultipartFile.fromPath(
        isVideo ? 'video' : 'image',
        file.path,
      );
      request.files.add(part);
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: 'Post Successful!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
      );
    } else {
      // Optionally, you can parse the responseBody for a more user-friendly error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post Failed: ${response.reasonPhrase ?? 'Unknown error'}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post Failed: ${e.toString()}')),
    );
    rethrow;
  }
}

Future<Map<String, String>?> _uploadFile({
  required File file,
  required String userid,
  required String token,
}) async {
  const uploadUrl = 'https://node-service-preprod.ancobridge.ai/api/fileUpload?entityType=community';
  final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

  request.headers.addAll({
    'userid': userid,
    'token': token,
  });

  final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
  final fileType = mimeType.startsWith('video/') ? 'video' : 'image';

  // Add the file to the request
  request.files.add(
    await http.MultipartFile.fromPath(
      fileType,
      file.path,
      contentType: MediaType.parse(mimeType),
    ),
  );

  try {
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decodedBody = jsonDecode(responseBody);

      if (decodedBody is Map && decodedBody['data'] is List && (decodedBody['data'] as List).isNotEmpty) {
        final Map<String, dynamic> fileData = decodedBody['data'][0];
        final String? uploadedUrl = fileData['url'];

        if (uploadedUrl != null) {
          log('File uploaded successfully: $uploadedUrl');
          return {
            'url': uploadedUrl,
            'type': fileType
          };
        }
      }

      log('File upload response has an unexpected format: $responseBody');
      return null;
    } else {
      log('File upload failed with status ${response.statusCode}: $responseBody');
      return null;
    }
  } catch (e, stackTrace) {
    log('An error occurred during file upload: $e');
    log('Stack trace: $stackTrace');
    return null;
  }
}

Future<void> submitCommunityPost({
  required BuildContext context,
  required List<File> mediaFiles,
  required String userid,
  required String token,
  required String content,
  required String communityId,
  required bool isAnonymous,
  bool isEdit = false,
  String? postId,
}) async {
  final totalBytes = await Future.wait(mediaFiles.map((f) => f.length())).then((values) => values.fold(0, (a, b) => a + b));
  const maxBytes = 50 * 1024 * 1024; // 50MB
  if (totalBytes > maxBytes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maximum total media size is 50MB')),
    );
    return;
  }

  try {
    final uploadResults = await Future.wait(mediaFiles.map((file) => _uploadFile(file: file, userid: userid, token: token)));

    if (uploadResults.any((result) => result == null)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not upload one or more files.')),
      );
      return;
    }

    final List<Map<String, String>> mediaUrls = uploadResults.whereType<Map<String, String>>().toList();

    final Map<String, dynamic> requestBody = {
      'content': content,
      'communityId': communityId,
      'isAnonymous': isAnonymous,
      if (mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
      if (isEdit && postId != null) 'postId': postId,
    };

    final url = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post');
    final headers = {
      'userid': userid,
      'token': token,
      'Content-Type': 'application/json',
    };

    final response = await (isEdit ? http.put(url, headers: headers, body: jsonEncode(requestBody)) : http.post(url, headers: headers, body: jsonEncode(requestBody)));

    Navigator.pop(context);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Post Updated Successfully' : 'Post Uploaded Successfully')),
      );
    } else {
      final errorData = jsonDecode(response.body);
      log('Error submitting post: ${response.statusCode}, Body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${errorData['message'] ?? 'An unknown error occurred.'}')),
      );
    }
  } catch (e) {
    Navigator.pop(context);
    log('An exception occurred in submitCommunityPost: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
    );
  }
}

Future<void> deletePost({
  required BuildContext context,
  required String communityId,
  required String postId,
  required String userid,
  required String token,
}) async {
  final url = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId/post?postId=$postId');

  final headers = {
    'userid': userid,
    'token': token,
  };

  try {
    final response = await http.delete(url, headers: headers);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post Deleted Successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed To Delete Post: ${response.reasonPhrase ?? 'Unknown error'}')),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed To Delete Post: ${error.toString()}')),
    );
  }
}
