import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

import '../../../core/firebase_upload.dart';

class MyVideosWork extends StatefulWidget {
  const MyVideosWork({super.key});

  @override
  State<MyVideosWork> createState() => _MyVideosWorkState();
}

class _MyVideosWorkState extends State<MyVideosWork> {
  FirebaseUpload upload = FirebaseUpload();
  late Future<void> _dataFutureVideos;
  final List<VideoPlayerController> _controllers = [];

  late final VideoEditorController _controller = VideoEditorController.file(
    File("${upload.videoURLs}"),
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 30),
  );

  @override
  void initState() {
    super.initState();
    _controller
        .initialize(aspectRatio: 9 / 16)
        .then((_) => setState(() {}))
        .catchError((error) {
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
    _dataFutureVideos = upload.getVideoData();
  }

  @override
  void dispose() {
    // Dispose of all VideoPlayerControllers when the widget is disposed
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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
                          final file = File(upload.videoURLs[index]);

                          VideoPlayerController controller =
                          VideoPlayerController.file(file);

                          // Add controller to list for disposal later
                          _controllers.add(controller);

                          return FutureBuilder(
                            future: controller.initialize(),
                            builder: (context, videoSnapshot) {
                              if (videoSnapshot.connectionState ==
                                  ConnectionState.done) {
                                final duration = controller.value.duration;

                                return GestureDetector(
                                  onTap: () {
                                   /* setState(() {
                                      if (controller.value.isPlaying) {
                                        controller.pause();
                                      } else {
                                        controller.play();
                                      }
                                    });*/
                                    CropGridViewer.preview(
                                        controller: _controller);
                                  },
                                  child: Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio:
                                        controller.value.aspectRatio,
                                        child: VideoPlayer(controller),
                                      ),
                                      // Play/Pause icon overlay
                                      if (!controller.value.isPlaying)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Icon(
                                            Icons.play_circle_filled,
                                            color:
                                            Colors.white.withOpacity(0.7),
                                            size: 50,
                                          ),
                                        ),
                                      // Video duration at the bottom right
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          color: Colors.black54,
                                          child: Text(
                                            _formatDuration(duration),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return const Center(
                                    child: CircularProgressIndicator());
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
