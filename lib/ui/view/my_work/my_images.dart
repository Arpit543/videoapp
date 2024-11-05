import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:videoapp/core/firebase_upload.dart';

class MyImagesWork extends StatefulWidget {
  const MyImagesWork({super.key});

  @override
  State<MyImagesWork> createState() => _MyImagesWorkState();
}

class _MyImagesWorkState extends State<MyImagesWork> {
  FirebaseUpload upload = FirebaseUpload();
  late Future<void> _dataFutureImages;

  @override
  void initState() {
    super.initState();
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
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: upload.lenImages,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Soft grey background
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.to(FullScreenImageViewer(
                            imageUrl: upload.imageURLs[index],
                          ));
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

