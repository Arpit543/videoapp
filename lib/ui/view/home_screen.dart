import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:videoapp/core/constants.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/image_editor/image_editor.dart';
import 'package:videoapp/ui/view/my_work/tab_vew.dart';
import 'package:videoapp/ui/view/splash_screen.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  FirebaseUpload upload = FirebaseUpload();
  File? galleryFile;
  File? cameraFile;

  String name = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    String? userName = Constants.getString(Constants.name);
    setState(() {
      name = userName ?? "User";
    });
  }

  Future<void> _pickVideo(int val) async {
    try {
      final pickedFile = await _picker.pickVideo(
        source: val == 0 ? ImageSource.gallery : ImageSource.camera,
      );

      if (pickedFile != null) {
        setState(() {
          galleryFile = File(pickedFile.path);
        });
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => VideoEditor(file: galleryFile!)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking video: $e')));
    }
  }

  Future<void> _pickImages(int val) async {
    final pickedFile = await _picker.pickImage(
      source: val == 0 ? ImageSource.gallery : ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        cameraFile = File(pickedFile.path);
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ImageEditor(file: cameraFile!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Hey $name',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          InkWell(
              onTap: () {
                Constants.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(Icons.power_settings_new, color: Colors.white,),
              ))
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  padding: const EdgeInsets.all(8),
                  children: [
                    _gridItem(
                      label: "Gallery Video",
                      onTap: () => _pickVideo(0),
                    ),
                    _gridItem(
                      label: "Camera Video",
                      onTap: () => _pickVideo(1),
                    ),
                    _gridItem(
                      label: "Gallery Image",
                      onTap: () => _pickImages(0),
                    ),
                    _gridItem(
                      label: "Camera Image",
                      onTap: () => _pickImages(1),
                    ),
                    _gridItem(
                      label: "My Work",
                      onTap: () {
                        Future.delayed(const Duration(milliseconds: 200),
                            () => Get.to(const MyWorkTab(index: 0)));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridItem({required String label, required Function onTap}) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
