import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:videoapp/core/firebase_upload.dart';

import '../../widget/common_theme.dart';

class MyImagesWork extends StatefulWidget {
  const MyImagesWork({super.key});

  @override
  State<MyImagesWork> createState() => _MyImagesWorkState();
}

class _MyImagesWorkState extends State<MyImagesWork> with TickerProviderStateMixin{
  FirebaseUpload upload = FirebaseUpload();
  late Future<void> _dataFutureImages;
  late final AnimationController animationController;

  @override
  void initState() {
    ThemeUtils.setStatusBarColor(const Color(0xff6EA9FF));
    super.initState();
    animationController = AnimationController(duration: const Duration(seconds: 5), vsync: this);
    _dataFutureImages = upload.getImageData();
  }

  Future<void> _refreshImages() async {
    await upload.getImageData();
    setState(() {
      _dataFutureImages = upload.getImageData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshImages,
          child: FutureBuilder(
            future: _dataFutureImages,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (upload.imageURLs.isEmpty) {
                return const Center(child: Text('No images found.'));
              } else {
                return AnimatedGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  initialItemCount: upload.lenImages,
                  padding: const EdgeInsets.all(10),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index, animation) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.bounceOut,
                      ),
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.fastLinearToSlowEaseIn,
                        ),
                        child: InkWell(
                          onTap: () {
                            Get.to(FullScreenImageViewer(imageUrl: upload.imageURLs[index]));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/anim/placeholder.gif',
                              image: upload.imageURLs[index],
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: PhotoView(
          filterQuality: FilterQuality.high,
          enableRotation: true,
          wantKeepAlive: false,
          backgroundDecoration: const BoxDecoration( color: Colors.white ),
          imageProvider: NetworkImage(imageUrl),
        ),
      ),
    );
  }
}

