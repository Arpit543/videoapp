import 'dart:async'; // Import to use Timer
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:story_view/story_view.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:http/http.dart' as http;

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
  List<StoryItem> storyData = [];

  @override
  void initState() {
    super.initState();
    _dataFutureImages = upload.getStoryData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStories();
    });
  }

  Future<void> _loadStories() async {
    try {
      List<String> storyItems = await _dataFutureImages;
      getInitializeList(storyItems);
    } catch (error) {
      if (kDebugMode) {
        print("Error fetching story data: $error");
      }
    }
  }

  void getInitializeList(List<String> storyItems) async {
    storyData.clear();
    for (var item in storyItems) {
      if (item.startsWith('http')) {
        if (_isImage(item)) {
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
          scheduleDeletion(item);
        } else if (_isVideo(item)) {
          _addVideoStory(item);
        } else if (_isTextFile(item)) {
          String storyText = await _fetchTextStory(item);
          storyData.add(
            StoryItem.text(
              title: storyText,
              backgroundColor: Colors.blueAccent,
              textStyle: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          );
        }
      } else {
        storyData.add(
          StoryItem.text(
            title: item,
            backgroundColor: Colors.blueAccent,
            textStyle: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        );
      }
    }
    setState(() {});
  }

  bool _isTextFile(String url) {
    return url.endsWith('.txt');
  }

  Future<String> _fetchTextStory(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Failed to load text story");
      }
    } catch (e) {
      throw Exception("Failed to fetch story text: $e");
    }
  }


  bool _isImage(String url) {
    return url.contains('.jpg') || url.contains('.png') || url.contains('.jpeg');
  }

  bool _isVideo(String url) {
    return url.contains('.mp4');
  }

  void _addVideoStory(String videoUrl) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          storyData.add(
            StoryItem.pageVideo(
              videoUrl,
              controller: storyController,
            ),
          );
        });
        _videoController!.play();
      }).catchError((error) {
        if (kDebugMode) {
          print("Error initializing video: $error");
        }
      });
    scheduleDeletion(videoUrl);
  }

  void scheduleDeletion(String fileUrl) {
    Timer(const Duration(hours: 24), () async {
      await upload.deleteStory(fileUrl);
      debugPrint("Story Deleted: $fileUrl");
    });
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
            inline: true,
            repeat: false,
            indicatorHeight: IndicatorHeight.small,
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