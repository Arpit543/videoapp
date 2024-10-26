import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/modules/main_editor/main_editor.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/my_work/tab_vew.dart';
import 'package:videoapp/ui/view/video_edit/find_song.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

class ImageEditor extends StatefulWidget {
  final File imageFile;
  final Function(String file) audioFile;

  const ImageEditor({super.key, required this.imageFile, required this.audioFile});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  FirebaseUpload upload = FirebaseUpload();
  bool isUploading = false;
  final AudioPlayer _player = AudioPlayer();
  ValueNotifier<bool> isMute = ValueNotifier(false);
  File? audio;

  Future<File> _convertBytesToFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${widget.imageFile.path.split("/").last}');
    await file.writeAsBytes(imageBytes);
    return file;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _player.pause();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Image Editor
          Container(
            color: Colors.white,
            child: ProImageEditor.file(
              widget.imageFile,
              configs: const ProImageEditorConfigs(),
              callbacks: ProImageEditorCallbacks(
                tuneEditorCallbacks: const TuneEditorCallbacks(),
                onImageEditingComplete: (Uint8List bytes) async {
                  setState(() {
                    isUploading = true; // Set uploading state to true
                  });

                  // Convert bytes to a File
                  File editedImageFile = await _convertBytesToFile(bytes);
                  String? finalPath;

                  try {
                    if (audio != null && audio!.path.isNotEmpty) {
                      // Add music to the edited image if audio is available
                      finalPath = await addMusicToImage(
                        imagePath: editedImageFile.path,
                        audioPath: audio!.path,
                      );

                      debugPrint("Final video path: $finalPath");

                      if (finalPath != null && finalPath.isNotEmpty) {
                        // Upload the final video to Firebase
                        await FirebaseUpload().uploadFileInStorage(
                          file: File(finalPath),
                          type: "Videos",
                          context: context,
                        );
                        Get.off(const MyWorkTab(index: 1));
                      } else {
                        debugPrint("Final path is empty. Unable to upload video.");
                        if (mounted) {
                          showSnackBar(
                            message: 'Final path is empty. Unable to upload video.',
                            context: context,
                            isError: true,
                          );
                        }
                      }
                    } else {
                      // Upload the edited image to Firebase
                      await FirebaseUpload().uploadFileInStorage(
                        file: editedImageFile,
                        type: "Images",
                        context: context,
                      );

                      Get.off(const MyWorkTab(index: 0));
                    }
                  } catch (e) {
                    // Handle any errors during the upload process
                    debugPrint("Error during upload process: $e");
                    if (mounted) {
                      showSnackBar(
                        message: 'An error occurred: $e',
                        context: context,
                        isError: true,
                      );
                    }
                  } finally {
                    // Always reset the uploading state and navigate back
                    setState(() {
                      isUploading = false;
                    });
                  }
                },
              ),
            ),
          ),

          Positioned(
            top: 35,
            right: Get.width / 2 - 45,
            child: IconButton(
              icon: const Icon(Icons.audiotrack),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FindSong(
                      audioFile: (file) async {
                        audio = File(file);
                        await _player.setAudioSource(AudioSource.file(file));
                        await _player.setLoopMode(LoopMode.one);
                        _player.setVolume(1.0);
                        _player.play();
                      },
                      isImageOrVideo: false,
                    ),
                  ),
                );
              },
            ),
          ),

          // Volume Icon
          Positioned(
            top: 35,
            right: Get.width / 2,
            child: ValueListenableBuilder<bool>(
              valueListenable: isMute,
              builder: (context, value, child) {
                return IconButton(
                  icon: Icon(value ? Icons.volume_off : Icons.volume_up),
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      isMute.value = !isMute.value;
                    });
                    _player.setVolume(isMute.value ? 0.0 : 1.0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Add Music to Image String command = '-loop 1 -i $imagePath -i $audioPath -c:v mpeg4 -c:a aac -b:a 192k -shortest $outputPath';
  Future<String?> addMusicToImage({required String imagePath, required String audioPath}) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: $imagePath');
      }

      final File audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file does not exist at path: $audioPath');
      }

      final Directory? externalDir = await getExternalStorageDirectory();
      final String basePath = '${externalDir?.parent.parent.parent.parent.path}/Download/';
      final String outputPath = "$basePath${DateTime.now().millisecondsSinceEpoch}.mp4";

      String command = '-loop 1 -i $imagePath -i $audioPath -c:v mpeg4 -c:a aac -b:a 192k -shortest $outputPath';

      await FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          debugPrint("Output Video Path: $outputPath");
        } else if (ReturnCode.isCancel(returnCode)) {
          debugPrint('FFmpeg command was canceled');
          throw Exception('FFmpeg command was canceled');
        } else {
          throw Exception('FFmpeg command failed with return code: $returnCode');
        }
      });

      return outputPath;
    } catch (e) {
      debugPrint('Error adding music to image: $e');
      return null;
    }
  }

}
