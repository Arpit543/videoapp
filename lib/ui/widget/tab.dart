import 'package:flutter/material.dart';

import '../view/home_screen.dart';
import '../view/story/story_view.dart';

class TabScreen extends StatefulWidget {
  const TabScreen({super.key});

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {

  PageController controller = PageController();
  ValueNotifier<double> currentPage = ValueNotifier(0);

  List pages = const [
    HomeScreen(),
    StoryViewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return pages[index];
                  },
                  onPageChanged: (value) {
                    currentPage.value = value.toDouble();
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}
