import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/modules/main_editor/main_editor.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/home_screen.dart';

class ImageEditor extends StatefulWidget {
  final File file;

  const ImageEditor({super.key, required this.file});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  FirebaseUpload upload = FirebaseUpload();
  bool _isUploading = false;

  Future<File> _convertBytesToFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${widget.file.path.split("/").last}');
    await file.writeAsBytes(imageBytes);
    return file;
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
          "Image Editor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: ProImageEditor.file(
              widget.file,
              configs: const ProImageEditorConfigs(),
              callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (Uint8List bytes) async {
                  setState(() {
                    _isUploading = true;
                  });
                  File editedImageFile = await _convertBytesToFile(bytes);
                  await upload.uploadFileInStorage(file: editedImageFile,type: "Images",context: context);
                  setState(() {
                    _isUploading = false;
                  });
                  Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => const HomeScreen(),),(route) => false,);
                },
              ),
            ),
          ),
          if (_isUploading)
            Center(
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6EA9FF)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
