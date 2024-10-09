import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  File? galleryFile;

  @override
  void initState() {
    _pickImage();
    super.initState();
  }

  _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        galleryFile = File(pickedFile.path);
      });
    } else {
      print("No Permission Given");
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
          "Post",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height / 1.5,
                    child: galleryFile != null ? Image.file(galleryFile!) : const Icon(Icons.add_box_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.crop),
                  Icon(Icons.edit),
                  Icon(Icons.add_a_photo_outlined),
                  Icon(Icons.delete),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
