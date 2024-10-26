import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/image_editor/image_editor.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

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
  final double height = 60;
  late VideoEditorController _controllerEdit;
  int length = 0;
  bool _showTrimSlider = false;

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

      _controllerEdit = VideoEditorController.file(
          File(widget.storyItems[index].story),
          minDuration: const Duration(seconds: 1),
          maxDuration: const Duration(seconds: 30),
          coverThumbnailsQuality: 100,
          trimThumbnailsQuality: 100);

      final File videoFile = File(widget.storyItems[index].story);
      _controller = VideoPlayerController.file(videoFile);

      await _controller!.initialize();
      setState(() {
        isLoadingVideo = false;
        _controller!.play();
        length = _controller!.value.duration.inSeconds;
        if (length > 30) {
          _showTrimSlider = true;
        }
        print("Length :- $length");
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
            if (_showTrimSlider)
              SizedBox(
                height: 100,
                child: Column(
                  children: _trimSlider(_controllerEdit),
                ),
              ),
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
                        if (length > 30) {
                          showSnackBar(
                              context: context,
                              message:
                                  "Please select video length up to 30 seconds");
                        } else {
                          _handleEdit(widget.storyItems);
                        }
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

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider(VideoEditorController controllerEdit) {
    final int duration = controllerEdit.videoDuration.inSeconds;
    final double pos = controllerEdit.trimPosition * duration;
    return [
      // Row(
      //   children: [
      //     Text(
      //       formatter(Duration(seconds: pos.toInt())),
      //       style: const TextStyle(
      //           fontWeight: FontWeight.bold), // Improved text visibility
      //     ),
      //     // const Expanded(child: SizedBox()),
      //     // const Expanded(child: SizedBox()),
      //     AnimatedOpacity(
      //       opacity: controllerEdit.isTrimming ? 1 : 0,
      //       duration: kThemeAnimationDuration,
      //       child: Row(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           Text(
      //             formatter(controllerEdit.startTrim),
      //             style: const TextStyle(
      //                 color: Colors.black), // Consistent text color
      //           ),
      //           const SizedBox(width: 10),
      //           Text(
      //             formatter(controllerEdit.endTrim),
      //             style: const TextStyle(
      //                 color: Colors.black), // Consistent text color
      //           ),
      //         ],
      //       ),
      //     ),
      //   ],
      // ),
      SizedBox(
        width: MediaQuery.of(context).size.width,
        child: TrimSlider(
          controller: controllerEdit,
          scrollController: ScrollController(keepScrollOffset: true),
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: controllerEdit,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      ),
    ];
  }

  void _handleEdit(List<StoryTypeModel> storyItems) {
    for (var item in storyItems) {
      print("URLS : $item");
      if (item.story.contains('.jpg') ||
          item.story.contains('.png') ||
          item.story.contains('.jpeg')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageEditor(file: File(item.story)),
          ),
        );
        break;
      } else if (item.story.contains('.mp4') ||
          item.story.contains('.mov') ||
          item.story.contains('.avi') ||
          item.story.contains('.mp3') ||
          item.story.contains('.mkv')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoEditor(file: File(item.story)),
          ),
        );
        break;
      } else {
        showSnackBar(
            context: context,
            message: "Unsupported file type for editing: $item");
        break;
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
