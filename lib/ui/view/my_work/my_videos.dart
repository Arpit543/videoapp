import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final Map<String, String> _thumbnailCache = {};
  final Map<String, File> _videoFileCache = {};

  @override
  void initState() {
    _dataFutureVideos = upload.getVideoData();
    super.initState();
  }

  Future<String?> _getCachedThumbnail(String videoUrl) async {
    if (_thumbnailCache.containsKey(videoUrl)) {
      return _thumbnailCache[videoUrl];
    }

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 200,
      quality: 100,
    );

    if (thumbnailPath != null) {
      _thumbnailCache[videoUrl] = thumbnailPath;
    }

    return thumbnailPath;
  }

  Future<File> _getCachedVideoFile(String videoUrl) async {
    if (_videoFileCache.containsKey(videoUrl)) {
      return _videoFileCache[videoUrl]!;
    }

    final file = await CachedFileHelper.urlToFile(videoUrl);
    _videoFileCache[videoUrl] = file;
    return file;
  }

  /// Function to delete video from Firebase Storage
  Future<void> _deleteVideo(String videoUrl, BuildContext context) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      String fileName = videoUrl.split('%2F').last.split('?').first;
      print(fileName);
      final storageRef = FirebaseStorage.instance.ref("${auth.currentUser!.uid}/Videos/$fileName");
      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video deleted successfully!')),);
      await upload.getVideoData();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting video: $e')),);
    }
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
                          final videoUrl = upload.videoURLs[index];
                          print(videoUrl);
                          return FutureBuilder<String?>(
                            future: _getCachedThumbnail(videoUrl),
                            builder: (context, thumbnailSnapshot) {
                              if (thumbnailSnapshot.hasError) {
                                return const Icon(Icons.error, color: Colors.red);
                              } else if (thumbnailSnapshot.hasData) {
                                return GestureDetector(
                                  onTap: () async {
                                    final file = await _getCachedVideoFile(videoUrl);
                                    Get.to(VideoResultPopup(video: file, title: false));
                                  },
                                  onLongPress: () async {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Video'),
                                        content: const Text('Are you sure you want to delete this video?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              print("Url :- ${videoUrl.tr}");
                                              await _deleteVideo(videoUrl, context);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
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
                                        File(thumbnailSnapshot.data!),
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


