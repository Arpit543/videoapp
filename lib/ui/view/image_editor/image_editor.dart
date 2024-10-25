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
                    isUploading = true;
                  });

                  File editedImageFile = await _convertBytesToFile(bytes);
                  String finalPath = "";

                  try {
                    if (audio != null && audio!.path.isNotEmpty) {
                      finalPath = await addMusicToImage(imagePath: editedImageFile.path, audioPath: audio!.path);
                      debugPrint("video path $finalPath");
                      if (finalPath.isNotEmpty) {
                        await FirebaseUpload().uploadFileInStorage(file: File(finalPath),type: "Videos",context: context,);
                      } else {
                        debugPrint("Final path is empty. Unable to upload video.");
                      }
                    } else {
                      debugPrint("Image path $editedImageFile");
                      await FirebaseUpload().uploadFileInStorage(file: editedImageFile,type: "Images",context: context,);
                    }
                  } catch (e) {
                    debugPrint("Error during upload process: $e");
                    if (mounted) showSnackBar(message: 'An error occurred: $e', context: context, isError: true);
                  } finally {
                    setState(() {
                      isUploading = false;
                    });

                    Get.off(const HomeScreen());
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
              color: Colors.grey,
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
                  color: Colors.grey,
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

  /// Add Music to Image
  Future<String> addMusicToImage({required String imagePath, required String audioPath}) async {
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

      // String command = "-y -i $imagePath -i $audioPath -map 0:v -map 1:a -c:v copy -shortest -pix_fmt yuv420p $outputPath";
      // String command = "-r 15 -f mp4 $audioPath -f image2 -i $imagePath -y $outputPath";
      // String command = '-loop 1 -i $imagePath -i $audioPath -c:v libx264 -tune stillimage -c:a aac -b:a 192k -shortest $outputPath';
      // String command = '-loop 1 -i $imagePath -i $audioPath -c:v libx264 -c:a aac -b:a 192k -shortest $outputPath';
      String command = '-loop 1 -i $imagePath -i $audioPath -c:v mpeg4 -c:a aac -b:a 192k -shortest $outputPath';

      await FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();
        final logs = await session.getAllLogs();
        logs.forEach((log) => debugPrint(log.getMessage()));

        if (ReturnCode.isSuccess(returnCode)) {
          debugPrint("Output Video Path: $outputPath");
        } else if (ReturnCode.isCancel(returnCode)) {
          debugPrint('FFmpeg command was canceled');
        } else {
          debugPrint('FFmpeg command failed with return code: $returnCode');
        }
      });

      return outputPath;
    } catch (e) {
      if (mounted) {
        showSnackBar(message: 'Error adding music to image: $e',context: context,isError: true,);
      }
      return "";
    }
  }
}
