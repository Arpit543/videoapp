import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/image_editor/image_editor.dart';
import 'package:videoapp/ui/view/story/story_view.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

class FileView extends StatefulWidget {
  final List<StoryTypeModel> pickedMedia;
  final Function(String file) videoFile;
  const FileView({super.key, required this.pickedMedia, required this.videoFile});

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  List<StoryTypeModel> pickedMediaStory = [];
  PageController pageController = PageController();
  VideoPlayerController? _controller;
  bool isLoadingVideo = true;
  bool isLoadingUpload = false;
  final double height = 60;
  int length = 0;

  @override
  void initState() {
    pickedMediaStory = widget.pickedMedia;
    super.initState();
    _initializeVideoController(0);
  }

  Future<void> _initializeVideoController(int index) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    if (pickedMediaStory[index].type == StoryType.video) {
      setState(() {
        isLoadingVideo = true;
      });

      final File videoFile = File(pickedMediaStory[index].story);
      _controller = VideoPlayerController.file(videoFile);

      await _controller!.initialize();
      setState(() {
        isLoadingVideo = false;
        length = _controller!.value.duration.inSeconds;
        _controller!.setLooping(true);
      });
    }
  }

  @override
  void dispose() {
    pickedMediaStory.clear();
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
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: InkWell(
            onTap: () { pickedMediaStory.clear(); _controller?.dispose(); Get.back();},
            child: const Icon(Icons.arrow_back, color:  Colors.white,),
        ),
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
                itemCount: pickedMediaStory.length,
                onPageChanged: (index) {
                  if (pickedMediaStory[index].type == StoryType.video) {
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
                      child: customStoryView(story: pickedMediaStory[index]),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SmoothPageIndicator(
                controller: pageController,
                count: pickedMediaStory.length,
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
                        print("Number ==> ${pickedMediaStory[pageController.page!.toInt()]}");
                        _handleEdit(pickedMediaStory[pageController.page!.toInt()], pageController.page!.toInt());
                        },
                      icon: const Center(
                        child: Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () async {
                        setState(() {
                          isLoadingUpload = true;
                        });

                        List<String> data = [];
                        for (int i = 0; i < pickedMediaStory.length; i++) {
                          StoryTypeModel imagePath = pickedMediaStory[i];
                          data.add(imagePath.story);
                        }

                        for (int i = 0; i < data.length; i++) {
                          await FirebaseUpload().uploadStoryInStorage(
                            images: [data[i]],
                            type: "Story",
                            context: context,
                          );
                        }

                        setState(() {
                          isLoadingUpload = false;
                        });

                        Get.off(const StoryViewScreen());

                      },
                      icon: Center(
                        child: isLoadingUpload ? const Center(child: CircularProgressIndicator()) : Text(
                          "Next",
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

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  void _handleEdit(StoryTypeModel storyItems, int index) {
    if (storyItems.story.contains('.jpg') || storyItems.story.contains('.png') || storyItems.story.contains('.jpeg')) {
      Get.to(ImageEditor(
        imageFile: File(storyItems.story),
        imageFileFunction: (file) {
          pickedMediaStory[index] = StoryTypeModel(story: file, type: StoryType.image);
          },
        isStory: true,
      ));
    } else if (storyItems.story.contains('.mp4') || storyItems.story.contains('.mov') || storyItems.story.contains('.avi') ||
        storyItems.story.contains('.mp3') || storyItems.story.contains('.mkv')) {
      Get.to(VideoEditor(
        videoFile: File(storyItems.story),
        videoFileFunction: (file) {
            pickedMediaStory[index] = StoryTypeModel(story: file, type: StoryType.video);
          },
        isStory: true,
      ));
    } else {
      showSnackBar(context: context, isError: true, message: "Unsupported file type for editing: ${storyItems.story}");
    }
  }

  Widget customStoryView({required StoryTypeModel story}) {
    final File mediaFile = File(story.story);

    switch (story.type) {
      case StoryType.image:
        return Image.file(
          mediaFile,
          fit: BoxFit.cover,
          width: MediaQuery.of(context).size.width,
        );

      case StoryType.video:
        if (_controller != null && _controller!.value.isInitialized) {
          return Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),
              Positioned(
                bottom: 20,
                child: IconButton(
                  icon: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                    });
                  },
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }

      default:
        return Text(story.story);
    }
  }

}
