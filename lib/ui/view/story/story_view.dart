import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:story_view/story_view.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/core/firebase_upload.dart';

class StoryViewScreen extends StatefulWidget {
  const StoryViewScreen({super.key});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController storyController = StoryController();
  final FirebaseUpload upload = FirebaseUpload();
  VideoPlayerController? _videoController;
  late Future<List<String>> _dataFutureImages;
  late List<StoryItem> storyData;

  @override
  void initState() {
    super.initState();
    _dataFutureImages = upload.getStoryData();
    storyData = [];
    WidgetsBinding.instance.addPostFrameCallback((_){
      _dataFutureImages.then((storyItems) {
        setState(() {
          getInitializeList(storyItems);
        });
      }).catchError((error) {
        if (kDebugMode) {
          print("Error fetching story data: $error");
        }
      });
    });
  }

  /*void getInitializeList(List<String> storyItems) {
    for (var item in storyItems) {
      if (item.startsWith('http') && (item.contains('.jpg') || item.contains('.png') || item.contains('.jpeg'))) {
        storyData.add(
          StoryItem.pageImage(
            url: item,
            caption: const Text(
              "A beautiful image",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            controller: storyController,
            imageFit: BoxFit.cover,
          ),
        );
      } else if (item.startsWith('http') && item.contains('.mp4')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(item));
        _videoController = VideoPlayerController.networkUrl(Uri.parse(item))
          ..initialize().then((_) {
            setState(() {});
            setState(() {});
          });

        VideoPlayer(_videoController!);

        storyData.add(
          StoryItem.pageVideo(
            item,
            controller: storyController,
          ),
        );
      } else {
        storyData.add(
          StoryItem.text(
            title: item,
            backgroundColor: Colors.blueAccent,
            textStyle: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        );
      }
    }
  }*/

  void getInitializeList(List<String> storyItems) {
    for (var item in storyItems) {
      if (item.startsWith('http') && (item.contains('.jpg') || item.contains('.png') || item.contains('.jpeg'))) {
        storyData.add(
          StoryItem.pageImage(
            url: item,
            caption: const Text(
              "A beautiful image",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            controller: storyController,
            imageFit: BoxFit.cover,
          ),
        );
      } else if (item.startsWith('http') && item.contains('.mp4')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(item))
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          }).catchError((error) {
            if (kDebugMode) {
              print("Error initializing video: $error");
            }
          });

        storyData.add(
          StoryItem.pageVideo(
            item,
            controller: storyController,
          ),
        );
      } else {
        storyData.add(
          StoryItem.text(
            title: item,
            backgroundColor: Colors.blueAccent,
            textStyle: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    storyController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<String>>(
        future: _dataFutureImages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData || storyData.isEmpty) {
            return const Center(
              child: Text(
                "No stories available.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return StoryView(
            controller: storyController,
            storyItems: storyData,
            progressPosition: ProgressPosition.top,
            indicatorColor: Colors.white,
            indicatorHeight: IndicatorHeight.large,
            indicatorOuterPadding: const EdgeInsets.all(10),
            indicatorForegroundColor: const Color(0xff6EA9FF),
            onStoryShow: (storyItem, index) {
              print("Showing story $index");
            },
            onComplete: () {
              print("Completed a cycle");
              Get.back();
            },
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Get.back();
              }
            },
          );
        },
      ),
    );
  }
}
