import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/image_editor/image_editor.dart';
import 'package:videoapp/ui/view/story/story_view.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

import '../../../core/firebase_upload.dart';
import '../../widget/common_theme.dart';

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
  final GlobalKey _tooltipKey = GlobalKey();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dynamic tooltip = _tooltipKey.currentState;
      tooltip?.ensureTooltipVisible();
    });

    ThemeUtils.setStatusBarColor(const Color(0xff6EA9FF));
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

      final videoDuration = _controller!.value.duration.inSeconds;
      if (videoDuration > 30) {
        if(mounted) showSnackBar(context: context,isError: true,message: "Please select a video up to 30 seconds.",);
      }

      setState(() {
        isLoadingVideo = false;
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
          'Add Story',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Tooltip(
            key: _tooltipKey,
            showDuration: const Duration(seconds: 2),
            exitDuration: const Duration(seconds: 2),
            padding: const EdgeInsets.all(5),
            height: 35,
            textStyle: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.normal),
            message: "You can discard any media",
            child: IconButton(
                onPressed: () {
                  if (pickedMediaStory.isEmpty && pageController.page!.toInt() == 0) {
                    Get.offAll(const HomeScreen());
                  } else {
                    int currentPage = pageController.page!.toInt();
                    if (currentPage < pickedMediaStory.length && currentPage >= 0) {
                      setState(() {
                        pickedMediaStory.removeAt(currentPage);
                        if (pickedMediaStory.isNotEmpty) {
                          if (currentPage >= pickedMediaStory.length) {
                            pageController.jumpToPage(pickedMediaStory.length - 1);
                          }
                          showSnackBar(context: context, isError: false, message: "Deleted");
                        } else {
                          Get.offAll(const HomeScreen());
                        }
                      });
                    }
                  }
                  debugPrint("Length ================ ${pickedMediaStory[pageController.page!.toInt()].type}");
                  },
                icon: const Icon(Icons.delete_outline, color: Colors.white,)),
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: pickedMediaStory.length,
              physics: const AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              allowImplicitScrolling: true,
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
            Positioned(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: pickedMediaStory.isEmpty ? null : SmoothPageIndicator(
                  controller: pageController,
                  count: pickedMediaStory.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: Colors.black,
                    dotHeight: 5,
                    dotWidth: 5,
                    dotColor: Colors.blue,
                    spacing: 5,
                    radius: 10,
                    expansionFactor: 5,
                    offset: 16,
                    strokeWidth: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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

                  bool isVideoDurationValid = true;
                  for (int i = 0; i < pickedMediaStory.length; i++) {
                    if (pickedMediaStory[i].type == StoryType.video) {
                      final File videoFile = File(pickedMediaStory[i].story);
                      final VideoPlayerController tempController = VideoPlayerController.file(videoFile);
                      await tempController.initialize();

                      final videoDuration = tempController.value.duration.inSeconds;
                      if (videoDuration > 30) {
                        isVideoDurationValid = false;

                        showSnackBar(context: context,isError: true,message: "Please select videos up to 30 seconds only. Video at index ${i + 1} exceeds 30 seconds.",);

                        await tempController.dispose();
                        break;
                      }
                      await tempController.dispose();
                    }
                  }

                  if (isVideoDurationValid) {
                    List<String> data = [];
                    for (int i = 0; i < pickedMediaStory.length; i++) {
                      StoryTypeModel imagePath = pickedMediaStory[i];
                      data.add(imagePath.story);
                    }

                    for (int i = 0; i < data.length; i++) {
                      await FirebaseUpload().uploadStoryInStorage(images: [data[i]],type: "Story",context: context,);
                    }

                    setState(() {
                      isLoadingUpload = false;
                    });

                    Get.off(const StoryViewScreen());
                  } else {
                    setState(() {
                      isLoadingUpload = false;
                    });
                  }
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
          setState(() {
            pickedMediaStory[index] = StoryTypeModel(story: file, type: StoryType.image);
          });
          pageController.jumpToPage(index);
          },
        isStory: true,
      ));
    } else if (storyItems.story.contains('.mp4') || storyItems.story.contains('.mov') || storyItems.story.contains('.avi') ||
        storyItems.story.contains('.mp3') || storyItems.story.contains('.mkv')) {
      Get.to(VideoEditor(
        videoFileForEditing: File(storyItems.story),
        videoFileForEditingFunction: (file) {
          setState(() {
            pickedMediaStory[index] = StoryTypeModel(story: file, type: StoryType.video);
            _initializeVideoController(index);
          });
          pageController.jumpToPage(index);
          },
        navigateForIsStory: true,
      ));
    } else {
      showSnackBar(context: context, isError: true, message: "Unsupported file type for editing: ${storyItems.story}");
    }
  }

  Widget customStoryView({required StoryTypeModel story}) {
    final File mediaFile = File(story.story);

    switch (story.type) {
      case StoryType.image:
        return Image.file( mediaFile, fit: BoxFit.fill);

        case StoryType.video:
          if (_controller != null && _controller!.value.isInitialized) {
            return Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(aspectRatio: _controller!.value.aspectRatio,child: VideoPlayer(_controller!)),
                Positioned(
                  child: IconButton(
                    icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 50, ),
                    onPressed: () { setState(() { if (_controller!.value.isPlaying) { _controller!.pause(); } else { _controller!.play(); } }); },
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
