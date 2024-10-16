import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:videoapp/ui/view/video_edit/export_result.dart';
import 'package:http/http.dart' as http;
import '../../../core/firebase_upload.dart';

class MyVideosWork extends StatefulWidget {
  const MyVideosWork({super.key});

  @override
  State<MyVideosWork> createState() => _MyVideosWorkState();
}

class _MyVideosWorkState extends State<MyVideosWork> {
  FirebaseUpload upload = FirebaseUpload();
  late Future<void> _dataFutureVideos;

  @override
  void initState() {
    super.initState();
    _dataFutureVideos = upload.getVideoData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await upload.getVideoData();
            setState(() {});
          },
          child: Column(
            children: [
              const SizedBox(height: 10),
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
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          return FutureBuilder<String?>(
                            future: VideoThumbnail.thumbnailFile(
                              video: upload.videoURLs[index],
                              imageFormat: ImageFormat.JPEG,
                              maxHeight: 200,
                              quality: 100,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Icon(Icons.error, color: Colors.red);
                              } else if (snapshot.hasData) {
                                return GestureDetector(
                                  onTap: () async {
                                    File file = await CachedFileHelper.urlToFile(upload.videoURLs[index]);
                                    Get.to(VideoResultPopup(video: file, title: false));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black12, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(snapshot.data!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              }
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CachedFileHelper {
  static final Map<String, File> _fileCache = {};

  static Future<File> urlToFile(String imageUrl) async {
    if (_fileCache.containsKey(imageUrl)) {
      return _fileCache[imageUrl]!;
    }

    var response = await http.get(Uri.parse(imageUrl));
    var documentDirectory = await getTemporaryDirectory();
    String filePath = '${documentDirectory.path}/${imageUrl.hashCode}.jpg';
    File file = File(filePath);
    file = await file.writeAsBytes(response.bodyBytes);
    _fileCache[imageUrl] = file;
    return file;
  }
}
