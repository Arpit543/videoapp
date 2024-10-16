import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/ui/view/home_screen.dart';

class StoryViewScreen extends StatefulWidget {
  final List<String> storyItems;

  const StoryViewScreen({super.key, required this.storyItems});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController storyController = StoryController();
  VideoPlayerController? _videoController;
  late List<String> story;

  @override
  void initState() {
    super.initState();
    getInitializeList();
  }

  List<StoryItem> storyData = [];


  void getInitializeList() {
    List<String> storyItems = widget.storyItems.toList();

    for (var item in storyItems) {
      if (item.endsWith('.jpg') || item.endsWith('.png') || item.endsWith('.jpeg')) {
        print("Image Item: $item");
        storyData.add(
          StoryItem.pageImage(
            url: item,
            caption: const Text("A beautiful image"),
            controller: StoryController(),
          ),
        );
      }
      else if (item.startsWith('http') && item.endsWith('.mp4')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(item))
          ..initialize().then((_) {
            setState(() {});
          });

        storyData.add(
          StoryItem.pageVideo(
            item,
            controller: StoryController(),
          ),
        );
      }
      else {
        storyData.add(
          StoryItem.text(
            title: item,
            backgroundColor: Colors.blue,
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
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: StoryView(
          controller: storyController,
          indicatorColor: Colors.white,
          indicatorHeight: IndicatorHeight.small,
          indicatorOuterPadding: const EdgeInsets.all(5),
          indicatorForegroundColor: const Color(0xff6EA9FF),
          progressPosition: ProgressPosition.top,
          repeat: false,
          inline: true,
          storyItems: storyData,
          onStoryShow: (storyItem, index) {
            print("Showing story $index");
          },
          onComplete: () {
            print("Completed a cycle");
            Navigator.pop(context);
          },
          onVerticalSwipeComplete: (direction) {
            if (direction == Direction.down) {
              Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => const HomeScreen(),),(route) => false,);
            }
          },
        ),
      ),
    );
  }
}
