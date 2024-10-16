import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/ui/view/home_screen.dart';

class FileView extends StatefulWidget {
  final List<StoryTypeModel> storyItems;

  FileView({super.key, required this.storyItems});

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  PageController pageController = PageController();
  VideoPlayerController? _controller; // Make it nullable

  @override
  void initState() {
    super.initState();
    _initializeVideoController(0);
  }

  Future<void> _initializeVideoController(int index) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    final File videoFile = File(widget.storyItems[index].story);
    _controller = VideoPlayerController.file(videoFile);

    await _controller!.initialize();
    setState(() {
      _controller!.play();
      _controller!.setLooping(true);
    });
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
                  _initializeVideoController(index);
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
                      onPressed: () {},
                      icon: Center(
                        child: Text(
                          "Edit",
                          style: TextStyle(
                            color: const CropGridStyle().selectedBoundariesColor,
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

  Widget customStoryView({required StoryTypeModel story}) {
    final File videoFile = File(story.story);
    switch (story.type) {
      case StoryType.Image:
        return Image.file(videoFile, fit: BoxFit.fill);
      case StoryType.Video:
        if (_controller != null && _controller!.value.isInitialized) {
          return VideoPlayer(_controller!);
        } else {
          return Center(child: CircularProgressIndicator()); // Show loading while initializing
        }
      default:
        return Text(story.story);
    }
  }
}
