import 'dart:io';
import 'dart:typed_data' show ByteData, Uint8List;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class CustomImageCropper extends StatefulWidget {
  final File imageFile;
  final Function(File) onCropComplete;

  const CustomImageCropper({
    Key? key,
    required this.imageFile,
    required this.onCropComplete,
  }) : super(key: key);

  @override
  _CustomImageCropperState createState() => _CustomImageCropperState();
}

class _CustomImageCropperState extends State<CustomImageCropper> {
  final GlobalKey _cropKey = GlobalKey();
  Offset _startOffset = Offset.zero;
  Offset _currentOffset = Offset.zero;
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Crop Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _cropImage,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _startOffset = details.localFocalPoint;
                        _baseScale = _scale;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = _baseScale * details.scale;
                          _currentOffset = details.localFocalPoint - _startOffset;
                        });
                      },
                      child: RepaintBoundary(
                        key: _cropKey,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width,
                          child: Stack(
                            children: [
                              Transform.scale(
                                scale: _scale,
                                child: Transform.translate(
                                  offset: _currentOffset,
                                  child: Image.file(
                                    widget.imageFile,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Circular mask
                              // Container(
                              //   decoration: BoxDecoration(
                              //     shape: BoxShape.circle,
                              //     color: Colors.black.withOpacity(0.5),
                              //   ),
                              // ),
                              // Circular border
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.rotate_left),
                    onPressed: () => _rotateImage(-90),
                  ),
                  IconButton(
                    icon: Icon(Icons.rotate_right),
                    onPressed: () => _rotateImage(90),
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_in),
                    onPressed: () => _zoom(1.1),
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_out),
                    onPressed: () => _zoom(0.9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _zoom(double factor) {
    setState(() {
      _scale *= factor;
    });
  }

  void _rotateImage(double degrees) {
    // Note: This is a placeholder. Actual rotation would require image processing
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rotation feature coming soon!')),
    );
  }

  Future<void> _cropImage() async {
    try {
      final RenderRepaintBoundary boundary =
          _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage();
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final File croppedFile = File('$tempPath/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');
      await croppedFile.writeAsBytes(pngBytes);

      if (mounted) {
        widget.onCropComplete(croppedFile);
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      print('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image')),
        );
      }
    }
  }
} 