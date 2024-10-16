import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:videoapp/ui/view/my_work/my_videos.dart';
import 'package:videoapp/ui/view/my_work/my_images.dart';

class MyWorkTab extends StatefulWidget {
  final int index;

  const MyWorkTab({super.key, required this.index});

  @override
  State<MyWorkTab> createState() => _MyWorkTabState();
}

class _MyWorkTabState extends State<MyWorkTab>
    with SingleTickerProviderStateMixin {
  TabController? tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 300), // Smooth transition
      initialIndex: widget.index,
    );
    tabController!.addListener(() {
      setState(() {}); // Update UI on tab switch
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          "My Work",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Custom TabBar with design improvements
          Container(
            color: Colors.white,
            child: TabBar(
              controller: tabController,
              indicatorColor: const Color(0xff6EA9FF), // Match app's theme
              indicatorWeight: 4, // Thicker underline for active tab
              labelColor: Colors.black, // Active tab text color
              unselectedLabelColor: Colors.grey, // Inactive tab text color
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Images"),
                Tab(text: "Videos"),
              ],
            ),
          ),
          // Smooth tab content transition
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: const BouncingScrollPhysics(), // Smooth scrolling effect
              children: const [
                MyImagesWork(),
                MyVideosWork(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
