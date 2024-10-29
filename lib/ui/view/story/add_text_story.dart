import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:videoapp/core/firebase_upload.dart'; // Assuming you have this set up

class AddTextStoryScreen extends StatefulWidget {
  const AddTextStoryScreen({super.key});

  @override
  State<AddTextStoryScreen> createState() => _AddTextStoryScreenState();
}

class _AddTextStoryScreenState extends State<AddTextStoryScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseUpload upload = FirebaseUpload();
  bool _isUploading = false;

    Future<void> _uploadTextStory() async {
    String textStory = _textController.text.trim();

    if (textStory.isEmpty) {
      Get.snackbar("Error","Please enter some text for the story.",snackPosition: SnackPosition.BOTTOM,backgroundColor: Colors.redAccent,colorText: Colors.white,);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await upload.uploadTextStoryToStorage(textStory, "Story");
    } catch (error) {
      Get.snackbar("Error","Failed to upload the story. Please try again.",snackPosition: SnackPosition.BOTTOM,backgroundColor: Colors.redAccent,colorText: Colors.white,);
    } finally {
      Get.snackbar("Success","Story uploaded successfully.",snackPosition: SnackPosition.BOTTOM,backgroundColor: Colors.green,colorText: Colors.white);
      _textController.clear();
      Get.back();
      setState(() {
        _isUploading = false;
      });
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
        title: const Text("Add Text Story", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Enter your story text below:",style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText: "Write your story here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            _isUploading ? const Center(child: CircularProgressIndicator(),)
                : ElevatedButton(
                    onPressed: _uploadTextStory,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Upload Story",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
