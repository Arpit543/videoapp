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
import 'package:videoapp/ui/view/my_work/tab_vew.dart';
import 'package:videoapp/ui/view/video_edit/export_result.dart';
import 'package:videoapp/ui/view/video_edit/find_song.dart';

import '../../widget/common_theme.dart';

class ImageEditor extends StatefulWidget {
  final File imageFile;
  final Function(String file) imageFileFunction;
  final bool isStory;

  const ImageEditor({super.key, required this.imageFile, required this.imageFileFunction, required this.isStory});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  FirebaseUpload upload = FirebaseUpload();
  bool isUploading = false;
  final AudioPlayer _player = AudioPlayer();
  ValueNotifier<bool> isMute = ValueNotifier(false);
  File? audio;

  @override
  void initState() {
    ThemeUtils.setStatusBarColor(const Color(0xff6EA9FF));
    super.initState();
  }

  Future<File> _convertBytesToFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${widget.imageFile.path.split("/").last}');
    await file.writeAsBytes(imageBytes);
    return file;
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
          Container(
            color: Colors.white,
            child: ProImageEditor.file(
              widget.imageFile,
              configs: const ProImageEditorConfigs(),
              callbacks: ProImageEditorCallbacks(
                tuneEditorCallbacks: const TuneEditorCallbacks(),
                onImageEditingComplete: (Uint8List bytes) async {
                  setState(() { isUploading = true; });

                  File editedImageFile = await _convertBytesToFile(bytes);

                  if(audio != null) {
                    setState(() {
                      isUploading = true;
                    });
                    await addMusicToImage(imagePath: editedImageFile.path, audioPath: audio!.path);
                    debugPrint("====== Audio Added ======");
                  } else {
                    widget.isStory ? widget.imageFileFunction(editedImageFile.path) : await FirebaseUpload().uploadImageVideoInStorage(file: editedImageFile,type: "Images",context: context,);
                    widget.isStory ? Navigator.pop(context) : Get.off(const MyWorkTab(index: 0));
                    debugPrint("====== Image Uploaded ======");
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
          if(isUploading == true)
            const Center(child: CircularProgressIndicator(color: Colors.blueGrey,),),
        ],
      ),
    );
  }

  /// Add music to image and create video using FFmpeg [addMusicToImage]
  Future<String?> addMusicToImage({required String imagePath, required String audioPath}) async {
    try {
      setState(() {
        isUploading = true;
      });
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

      final audioDuration = _player.duration!.inSeconds;
      String command = '-loop 1 -i $imagePath -i $audioPath -c:v mpeg4 -c:a aac -b:a 192k -shortest -t $audioDuration $outputPath';

      await FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          debugPrint("Output Video Path: $outputPath");

          widget.isStory ? widget.imageFileFunction(outputPath) : await Get.off(VideoResultPopup(video: File(outputPath),isShowWidget: true));
          if (widget.isStory && mounted) Navigator.pop(context);

          setState(() {
            isUploading = false;
          });
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
