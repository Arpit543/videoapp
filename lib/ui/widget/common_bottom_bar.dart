import 'package:flutter/material.dart';
import 'package:videoapp/ui/view/add_post.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/video_editor.dart';

class CommonBottomBar extends StatefulWidget {
  const CommonBottomBar({super.key});

  @override
  State<CommonBottomBar> createState() => _CommonBottomBarState();
}

class _CommonBottomBarState extends State<CommonBottomBar> {
  List pages = [const HomeScreen(), const VideoEditor()];
  ValueNotifier<int> currentIndex = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex.value],
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff4A90E2), Color(0xff6EA9FF)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex.value = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: currentIndex.value == 0 ? const Border(bottom: BorderSide(color: Colors.white, width: 3)) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      color: currentIndex.value == 0 ? Colors.white : Colors.white54,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex.value = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: currentIndex.value == 1 ? const Border(bottom: BorderSide(color: Colors.white, width: 3)): null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_box_outlined,
                      color: currentIndex.value == 1 ? Colors.white : Colors.white54,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
