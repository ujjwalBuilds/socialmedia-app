import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';


class StoryService {
  // Method to compress image while preserving dimensions
  Future<File> _compressImage(File file) async {
    print('Starting image compression...');
    
    // Read the image file
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Preserve the original dimensions - don't resize
    // Just apply quality compression without changing dimensions
    final processedImage = image;
    
    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    // Save with quality compression only (no dimension changes)
    await compressedFile.writeAsBytes(
      img.encodeJpg(processedImage, quality: 90),
    );
    
    print('Image compressed. Original size: ${bytes.length}, Compressed size: ${await compressedFile.length()}');
    return compressedFile;
  }

  // Method to upload a story
  Future<void> uploadStory(File mediaFile) async {
    print('Starting story upload...');
    print('Media path: ${mediaFile.path}');
    
    if (!await mediaFile.exists()) {
      print('Error: Media file does not exist at path: ${mediaFile.path}');
      throw Exception('Media file does not exist');
    }

    final url = Uri.parse('${BASE_URL}api/upload-story');
    final request = http.MultipartRequest('POST', url);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('user_id') ?? '';
    final String token = prefs.getString('user_token') ?? '';

    if (userId.isEmpty || token.isEmpty) {
      print('Error: Missing user ID or token');
      throw Exception('Missing user credentials');
    }

    request.headers['userId'] = userId;
    request.headers['token'] = token;

    request.fields['privacy'] = '1';
    request.fields['contentType'] = 'image';

    try {
      // Compress while preserving dimensions and upload image
      final compressedFile = await _compressImage(mediaFile);
      final imageFile = await http.MultipartFile.fromPath('image', compressedFile.path);
      request.files.add(imageFile);
      
      print('Sending upload request...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Response status code: ${response.statusCode}');
      print('Response body: $responseBody');
      
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
        msg: "Story posted successfully!",
        gravity: ToastGravity.BOTTOM,
      );
        print('Story uploaded successfully');
      } else {
        print('Failed to upload story. Status Code: ${response.statusCode}');
        print('Response body: $responseBody');
        throw Exception('Failed to upload story: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading story: $e');
      throw e;
    }
  }
}


