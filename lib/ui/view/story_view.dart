import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';

class StoryViewScreen extends StatefulWidget {
  const StoryViewScreen({super.key});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController storyController = StoryController();

  final List<String> storyImages = [
    "https://picsum.photos/250?image=10",
    "https://picsum.photos/250?image=20",
    "https://picsum.photos/250?image=30",
    "https://picsum.photos/250?image=40",
    "https://picsum.photos/250?image=50",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Stories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: StoryView(
        controller: storyController,
        storyItems: storyImages
            .map(
              (url) => StoryItem.pageProviderImage(
            NetworkImage(url),
            duration: const Duration(seconds: 2),
          ),
        )
            .toList(),
        onStoryShow: (storyItem, index) {
          print("Showing story $index");
        },
        onComplete: () {
          print("Completed a cycle");
          Navigator.pop(context);
        },
        progressPosition: ProgressPosition.top,
        repeat: false,
        inline: true,
        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
