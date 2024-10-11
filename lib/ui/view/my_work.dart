import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:videoapp/core/firebase_upload.dart';

class MyWork extends StatefulWidget {
  const MyWork({super.key});

  @override
  State<MyWork> createState() => _MyWorkState();
}

class _MyWorkState extends State<MyWork> {
  FirebaseUpload upload = FirebaseUpload();
  late Future<void> _dataFutureImages;
  late Future<void> _dataFutureVideos;

  @override
  void initState() {
    super.initState();
    _dataFutureImages = upload.getImageData();
    _dataFutureVideos = upload.getImageData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "My Work",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
            onRefresh: () async {
              //await upload.getData();
              setState(() {});
            },
            child: Column(
              children: [
                const Center(
                  child: Text("Images"),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _dataFutureImages,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        return GridView.builder(
                          itemCount: upload.lenImages,
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            return Image.network(
                              upload.imageURLs[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error);
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                const Center(
                  child: Text("Videos"),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _dataFutureVideos,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        return GridView.builder(
                          itemCount: upload.lenVideos,
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            return SizedBox();
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
