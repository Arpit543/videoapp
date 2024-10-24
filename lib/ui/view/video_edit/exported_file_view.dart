import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/my_work/tab_vew.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

class ExportedFileView extends StatefulWidget {
  final File videoFile;

  const ExportedFileView({super.key, required this.videoFile});

  @override
  State<ExportedFileView> createState() => _ExportedFileViewState();
}

class _ExportedFileViewState extends State<ExportedFileView> {
  late final VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _controller.setVolume(1);
          _controller.setLooping(true);
        });
      });
    super.initState();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying ? _controller.pause() : _controller.play();
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Edited Video",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            GestureDetector(
              onTap: _togglePlayPause,
              child: AnimatedOpacity(
                opacity: _isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Color(0xff6EA9FF),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 2,
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  "Discard",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff6EA9FF),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: TextButton(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        await FirebaseUpload().uploadFileInStorage(file: widget.videoFile,type: "Videos",context: context,);

                        setState(() {
                          _isLoading = false;
                        });

                       Get.off(const MyWorkTab(index: 1));
                      },
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
