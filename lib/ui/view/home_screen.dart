import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:videoapp/ui/view/trimmer_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Trimmer _trimmer = Trimmer();
  final ImagePicker _picker = ImagePicker();

  File? galleryFile;

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        galleryFile = File(pickedFile.path);
      });
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrimmerView(galleryFile!),
          ));
      await _trimmer.loadVideo(videoFile: File(pickedFile.path));
    }
  }

  Future<void> _pickVideos() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        galleryFile = File(pickedFile.path);
      });
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrimmerView(galleryFile!),
          ));
      await _trimmer.loadVideo(videoFile: File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        centerTitle: true,
        title: const Text(
          "Video App",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Lottie.asset("assets/anim/anim_1.json"),
            Center(
              child: InkWell(
                onTap: () {
                  _pickVideo();
                },
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff4A90E2), Color(0xff6EA9FF)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: const Center(
                    child: Text(
                      "Choose from gallery",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: InkWell(
                onTap: () {
                  _pickVideo();
                },
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff4A90E2), Color(0xff6EA9FF)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: const Center(
                    child: Text(
                      "Choose from camera",
                      style: TextStyle(color: Colors.white),
                    ),
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
