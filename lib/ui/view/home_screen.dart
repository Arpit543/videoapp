import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:videoapp/core/constants.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/image_editor/image_editor.dart';
import 'package:videoapp/ui/view/my_work/tab_vew.dart';
import 'package:videoapp/ui/view/splash_screen.dart';
import 'package:videoapp/ui/view/story/file_view.dart';
import 'package:videoapp/ui/view/story/story_view.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

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

  List<StoryTypeModel> storyItems = [];

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
      final pickedFile = await _picker.pickVideo(source: val == 0 ? ImageSource.gallery : ImageSource.camera,);

      if (pickedFile != null) {
        setState(() {
          galleryFile = File(pickedFile.path);
        });
        Get.to(VideoEditor(file: File(pickedFile.path)));
      }
    } catch (e) {
      showSnackBar(context: context, message: "Error picking video: $e");
    }
  }

  Future<void> _pickImages(int val) async {
    final pickedFile = await _picker.pickImage(source: val == 0 ? ImageSource.gallery : ImageSource.camera,);
    if (pickedFile != null) {
      setState(() {
        cameraFile = File(pickedFile.path);
      });
      Get.to(ImageEditor(file: cameraFile!));
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
        leading: InkWell(
          onTap: () async {
            try {

              final pickedFiles = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowMultiple: true,
                withData: true,
                allowedExtensions: ['jpg', 'jpeg', 'png', 'mov', 'mp4', 'mkv','avi'],
              );

              if (pickedFiles != null) {
                for (final file in pickedFiles.files) {
                  final path = file.path;
                  if (path != null) {
                    if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
                      storyItems.add(StoryTypeModel(story: path, type: StoryType.image));
                    } else if (path.endsWith('.mov') || path.endsWith('.mp4') || path.endsWith('.mkv') || path.endsWith('.avi')) {storyItems.add(StoryTypeModel(story: path, type: StoryType.video));
                    }
                  }
                }
              }
              setState(() {});
              if (storyItems.isNotEmpty) Get.to(FileView(storyItems: storyItems));
            } catch (e) {
              showSnackBar(context: context, message: "Error picking media: $e");
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(Icons.add_box_outlined, color: Colors.white),
          ),
        ),
        title: Text(
          'Hey $name',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          InkWell(
            onTap: () {
              Constants.clear();
              Get.offAll(const SplashScreen());
            },
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(Icons.power_settings_new, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  ClipOval(
                    child: InkWell(
                      onTap: () => Get.to(const StoryViewScreen()),
                      child: Image.network(
                        "https://picsum.photos/250",
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "My Story",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xff6EA9FF)),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  padding: const EdgeInsets.all(8),
                  children: [
                    _gridItem(
                      label: "Gallery Video",
                      icon: Icons.video_library,
                      onTap: () => _pickVideo(0),
                    ),
                    _gridItem(
                      label: "Camera Video",
                      icon: Icons.videocam,
                      onTap: () => _pickVideo(1),
                    ),
                    _gridItem(
                      label: "Gallery Image",
                      icon: Icons.image,
                      onTap: () => _pickImages(0),
                    ),
                    _gridItem(
                      label: "Camera Image",
                      icon: Icons.camera_alt,
                      onTap: () => _pickImages(1),
                    ),
                    _gridItem(
                      label: "My Work",
                      icon: Icons.work,
                      onTap: () => Get.to(const MyWorkTab(index: 0)),
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

  Widget _gridItem({required String label, required IconData icon, required Function onTap}) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xff6EA9FF)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum StoryType { image, video }


class StoryTypeModel {
  final String story;
  final StoryType type;

  StoryTypeModel({required this.story, required this.type});
}
