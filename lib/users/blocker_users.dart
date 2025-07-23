import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_kraya/Providers/loops%20provider.dart';
import 'package:flutter_application_kraya/components/customAppBar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;


class AddFromInstagram extends ConsumerStatefulWidget {
 final List<String?>? videoUrls ;
  final Function(Uint8List) onVideoSelected;
  const AddFromInstagram({Key? key
  , this.videoUrls,
  required this.onVideoSelected,
  }) : super(key: key);

  @override
  ConsumerState<AddFromInstagram> createState() => _AddFromInstagramState();
}

class _AddFromInstagramState extends ConsumerState<AddFromInstagram> {
  final TextEditingController usernameController = TextEditingController();
 VideoPlayerController? controller;



final selectedVideoProvider = StateProvider<String?>((ref) => null);

Widget loopsContainer(String? videoUrl, WidgetRef ref) {
  final selectedVideo = ref.watch(selectedVideoProvider);

  return GestureDetector(
    onTap: () {
      // Select video
      ref.read(selectedVideoProvider.notifier).state = videoUrl;
    },
    onLongPress: () {
      // Long press to select video
      ref.read(selectedVideoProvider.notifier).state = videoUrl;
    },
    child: Stack(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _VideoPlayerWidget(
              videoUrl: videoUrl ?? '',
              onControllerInitialized: (VideoPlayerController ctrl) {
                // Update the controller if necessary
              },
            ),
          ),
        ),
        if (selectedVideo == videoUrl)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                
                ElevatedButton(
            onPressed: () => _handleUpload(context,  selectedVideo),
            child: const Text("Upload"),
          ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}


Future<void> _handleUpload(BuildContext context, String? videoUrl) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.get(Uri.parse(videoUrl??''));
      print("this is the video url>>>>>>>>>>>>>  $videoUrl");
      if (response.statusCode == 200) {
        print("download video successfully>>>>>>>>>>>>>>>");
        Navigator.of(context).pop(); // Close loading dialog
       widget. onVideoSelected(response.bodyBytes); // Return video bytes via callback
        context.pop(); // Navigate back to the previous screen
      } else {
        print("Failed to download video>>>>>>>>>>>>>>>");
        throw Exception("Failed to download video");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error: $e',
            style: TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1, milliseconds: 500),
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
   // final videoUrls = ref.watch(instagramVideosProvider);
    final selectedVideoProvider = StateProvider<String?>((ref) => null);

  final selectedVideo = ref.watch(selectedVideoProvider);

  return Scaffold(
    appBar: CustomAppBar(title: "Add from Insta"),
    body: Column(
      children: [
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisExtent: 250,
            ),
            itemCount: widget.videoUrls?.length ?? 0,
            itemBuilder: (context, index) {
              final videoUrl = widget.videoUrls?[index];
              return loopsContainer(videoUrl, ref);
            },
          ),
        ),
        if (selectedVideo != null)
          ElevatedButton(
            onPressed: () => _handleUpload(context,  selectedVideo),
            child: const Text("Upload"),
          ),
      ],
    ),
  );
  }
  
}


class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final Function(VideoPlayerController) onControllerInitialized;

  const _VideoPlayerWidget({required this.videoUrl, Key? key, required this.onControllerInitialized}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller.initialize();
      widget.onControllerInitialized(_controller);
      if (mounted) {
        setState(() {});
        _controller.play();
      _controller.setVolume(0);
        _controller.setLooping(true);
      }
    } catch (e) {
      print('Video Player Error: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e is FormatException ? 'Invalid URL format' : 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
   // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_isError) {
      return Container(
        color: Colors.black12,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Video Load Error',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C54E9)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
