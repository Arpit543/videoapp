import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:videoapp/ui/view/my_work/my_videos.dart';

import '../../widget/common_snackbar.dart';
import 'my_images.dart';

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
    tabController = TabController(length: 2,vsync: this,animationDuration: const Duration(seconds: 1),initialIndex: widget.index);
    tabController!.addListener(() {
      setState(() {});
    });
    super.initState();
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
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: Text(
          "My Work".tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          ColoredTabBar(
            colors: Colors.white,
            tabBar: TabBar(
              controller: tabController,
              automaticIndicatorColorAdjustment: true,
              tabs: const [
                Tab(
                  child: Text("Images", style: TextStyle(color: Colors.black)),
                ),
                Tab(
                  child: Text("Videos", style: TextStyle(color: Colors.black)),
                )
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [MyImagesWork(), MyVideosWork()],
            ),
          )
        ],
      ),
    );
  }
}
