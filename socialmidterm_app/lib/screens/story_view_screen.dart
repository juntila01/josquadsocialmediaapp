import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Logic: Required for playing video stories

class StoryViewScreen extends StatefulWidget {
  // Logic: Data passed from SidebarUsers or HomeScreen to view a specific story
  final String url; // Connection: The URL of the story file (Image or Video)
  final String type; // Logic: 'image' or 'video' to determine which player to use
  final int durationSeconds; // UI: How long the story stays on screen (default 5s)

  const StoryViewScreen({
    Key? key,
    required this.url,
    required this.type,
    this.durationSeconds = 5,
  }) : super(key: key);

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with TickerProviderStateMixin {
  late AnimationController _progressController; // UI: Controls the "Instagram-style" progress bar at the top
  VideoPlayerController? _videoController; // Logic: Controller for video playback
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    // 1. Setup the progress bar controller
    // Logic: This creates the timing for how fast the progress bar fills up
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    // 2. Handle Video vs Image Logic
    if (widget.type.toLowerCase() == 'video') {
      // Connection: Connects to the video URL to stream the story content
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
            // Logic: Overrides the default 5s to match the actual length of the video file
            _progressController.duration = _videoController!.value.duration;
            _videoController!.play();
            _progressController.forward(); // Starts the progress bar and video together
          });
        });
    } else {
      // Logic: It's an image, so start the 5-second countdown immediately
      _progressController.forward();
    }

    // 3. Auto-close when finished
    // Logic: Once the progress bar reaches 100%, the screen automatically pops (closes)
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    // Logic: Clean up controllers to prevent memory leaks when the story is closed
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // UI: Immersive black background for the story viewer
      body: GestureDetector(
        // Logic: Allows users to tap anywhere on the screen to skip/close the story early
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            // --- THE CONTENT (VIDEO OR IMAGE) ---
            Center(
              child: widget.type.toLowerCase() == 'video'
                  ? (_isVideoInitialized
                  ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
                  : const CircularProgressIndicator(color: Colors.white))
                  : Image.network(
                widget.url,
                fit: BoxFit.contain, // UI: Ensures the whole image is visible without cropping
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(color: Colors.white);
                },
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),

            // --- TOP PROGRESS BAR & UI ---
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  // UI: The animated white bar indicating how much time is left in the story
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 3,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // UI: Manual close button if the user doesn't want to wait
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}