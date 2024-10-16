import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/image_editor/image_editor.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';

class FileView extends StatefulWidget {
  final List<StoryTypeModel> storyItems;

  const FileView({super.key, required this.storyItems});

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  PageController pageController = PageController();
  VideoPlayerController? _controller;
  bool isLoadingVideo = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoController(0);
  }

  Future<void> _initializeVideoController(int index) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    if (widget.storyItems[index].type == StoryType.Video) {
      setState(() {
        isLoadingVideo = true;
      });

      final File videoFile = File(widget.storyItems[index].story);
      _controller = VideoPlayerController.file(videoFile);

      await _controller!.initialize();
      setState(() {
        isLoadingVideo = false;
        _controller!.play();
        _controller!.setLooping(true);
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: PageView.builder(
                controller: pageController,
                itemCount: widget.storyItems.length,
                onPageChanged: (index) {
                  if (widget.storyItems[index].type == StoryType.Video) {
                    _initializeVideoController(index);
                  } else {
                    setState(() {
                      _controller?.dispose();
                      _controller = null;
                    });
                  }
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: customStoryView(story: widget.storyItems[index]),
                    ),
                  );
                },
              ),
            ),
            // Smooth Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SmoothPageIndicator(
                controller: pageController,
                count: widget.storyItems.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Color(0xff6EA9FF),
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
            ),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xff6EA9FF),
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () {
                        widget.storyItems.clear();
                        Navigator.pop(context);
                      },
                      icon: const Center(
                        child: Text(
                          "Discard",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () {
                        _handleEdit(widget.storyItems);
                      },
                      icon: Center(
                        child: Text(
                          "Edit",
                          style: TextStyle(
                            color:
                                const CropGridStyle().selectedBoundariesColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  void _handleEdit(List<StoryTypeModel> storyItems) {
    for (var item in storyItems) {
      print("URLS : $item");
      if (item.story.contains('.jpg') || item.story.contains('.png') || item.story.contains('.jpeg')) {
        // Navigate to Image Editor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageEditor(file: File(item.story)), // Replace with your Image Editor Screen
          ),
        );
        break; // Exit the loop after navigating
      } else if (item.story.contains('.mp4') || item.story.contains('.mov') || item.story.contains('.avi') || item.story.contains('.mp3') || item.story.contains('.mkv')) {
        // Navigate to Video Editor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoEditor(file: File(item.story)), // Replace with your Video Editor Screen
          ),
        );
        break; // Exit the loop after navigating
      } else {
        // Handle unsupported file types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unsupported file type for editing: $item.contains()'),
          ),
        );
        break; // Exit after showing the message
      }
    }
  }

  Widget customStoryView({required StoryTypeModel story}) {
    final File mediaFile = File(story.story);
    switch (story.type) {
      case StoryType.Image:
        return Image.file(
          mediaFile,
          fit: BoxFit.cover,
          width: MediaQuery.of(context).size.width,
        );
      case StoryType.Video:
        if (_controller != null && _controller!.value.isInitialized) {
          return isLoadingVideo
              ? const Center(child: CircularProgressIndicator())
              : VideoPlayer(_controller!);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      default:
        return Text(story.story);
    }
  }
}
