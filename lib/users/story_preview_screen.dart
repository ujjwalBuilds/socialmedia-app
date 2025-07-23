import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:socialmedia/user_apis/uploadstory.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:photo_view/photo_view.dart';
import 'package:screenshot/screenshot.dart';

class StoryEditor extends StatefulWidget {
  final File selectedImage;

  const StoryEditor({required this.selectedImage, Key? key}) : super(key: key);

  @override
  State<StoryEditor> createState() => _StoryEditorState();
}

class _StoryEditorState extends State<StoryEditor> {
  bool _isUploading = false;
  File? _processedImage;
  final ScreenshotController _screenshotController = ScreenshotController();
  PhotoViewControllerBase? _photoViewController;
  double _scale = 1.0;
  double _minScale = 0.5;
  double _maxScale = 2.5;
  Offset _position = Offset.zero;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController(initialScale: 1.0);
    _photoViewController?.outputStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _scale = state.scale ?? 1.0;
          _position = state.position ?? Offset.zero;
        });
      }
    });
  }

  Future<void> _captureAndUpload() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Set screenshot properties to ensure exact dimensions are captured
      final imageBytes = await _screenshotController.capture(
        pixelRatio: 1.0, // Use consistent pixel ratio 
        delay: Duration(milliseconds: 100), // Small delay to ensure render is complete
      );
      
      if (imageBytes == null) {
        throw Exception("Failed to capture image");
      }

      // Save the screenshot to a file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'story_${Uuid().v4()}.png';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);
      
      _processedImage = tempFile;

      // Upload the processed image with its adjusted dimensions preserved
      StoryService storyService = StoryService();
      await storyService.uploadStory(_processedImage!);

      Fluttertoast.showToast(
        msg: "Story posted successfully!",
        gravity: ToastGravity.BOTTOM,
      );

      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to post story: ${e.toString()}",
        gravity: ToastGravity.BOTTOM,
      );
      print("Upload error: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.black,
          title: Text(
            "Edit Story",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          actions: [
            InkWell(
              onTap: _captureAndUpload,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF7400A5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.0.w, vertical: 4),
                    child: _isUploading
                        ? LoadingAnimationWidget.threeArchedCircle(
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            "Post",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  color: Colors.black,
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 16 / 9,
                      child: PhotoView.customChild(
                        backgroundDecoration: BoxDecoration(color: Colors.transparent),
                        controller: _photoViewController,
                        minScale: _minScale,
                        maxScale: _maxScale,
                        initialScale: 1.0,
                        child: Image.file(
                          widget.selectedImage,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildControlsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Adjust your image",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.zoom_out,
                onPressed: () {
                  if (_scale > _minScale) {
                    _photoViewController?.scale = (_scale - 0.1).clamp(_minScale, _maxScale);
                  }
                },
              ),
              SizedBox(width: 20.0),
              _buildControlButton(
                icon: Icons.crop_free,
                onPressed: () {
                  _photoViewController?.position = Offset.zero;
                  _photoViewController?.scale = 1.0;
                },
              ),
              SizedBox(width: 20.0),
              _buildControlButton(
                icon: Icons.zoom_in,
                onPressed: () {
                  if (_scale < _maxScale) {
                    _photoViewController?.scale = (_scale + 0.1).clamp(_minScale, _maxScale);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 10.0),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 42.0,
        height: 42.0,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24.0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _photoViewController?.dispose();
    super.dispose();
  }
}
