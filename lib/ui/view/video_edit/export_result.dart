import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

import '../../widget/common_theme.dart';
import '../my_work/tab_vew.dart';

Future<void> _getImageDimension(File file, {required Function(Size) onResult}) async {
  var decodedImage = await decodeImageFromList(file.readAsBytesSync());
  onResult(Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()));
}

String _fileMBSize(File file) => ' ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB';

/// Class to show Video after edit [VideoResultPopup]
/// Class to show Cover Image from image and video [CoverResultPopup]
/// Show File Description When Video or Image file Exported [FileDescription]

class VideoResultPopup extends StatefulWidget {
  final File video;
  final bool isShowWidget;

  const VideoResultPopup({super.key, required this.video, required this.isShowWidget});

  @override
  State<VideoResultPopup> createState() => _VideoResultPopupState();
}

class _VideoResultPopupState extends State<VideoResultPopup> {
  VideoPlayerController? _controller;
  Size _fileDimension = Size.zero;
  late final bool _isGif = path.extension(widget.video.path).toLowerCase() == ".gif";
  late String _fileMbSize;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    ThemeUtils.setStatusBarColor(const Color(0xff6EA9FF));
    super.initState();
    _controller = VideoPlayerController.file(widget.video)
      ..initialize().then((_) {
        setState(() {
          _fileDimension = _controller?.value.size ?? Size.zero;
        });
        _controller?.setLooping(true);
      });
    _fileMbSize = _fileMBSize(widget.video);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying ? _controller?.pause() : _controller?.play();
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xff6EA9FF),
          elevation: 1.0,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(
            widget.isShowWidget == true ? "Edited Video" : "My Video",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _fileDimension.aspectRatio != 0 ? _fileDimension.aspectRatio : _controller!.value.aspectRatio,
                        child: _isGif ? Image.file(widget.video, fit: BoxFit.cover) : VideoPlayer(_controller!),
                      ),
                    ),
                    if (!_isGif) // Only show for video
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
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: widget.isShowWidget == true ?
                      FileDescription(
                        description: {
                          if (!_isGif)
                            'Video duration': '${((_controller?.value.duration.inMilliseconds ?? 0) / 1000).toStringAsFixed(2)}s',
                          'Video ratio': Fraction.fromDouble(_fileDimension.aspectRatio).reduce().toString(),
                          'Video dimension': _fileDimension.toString(),
                          'Video size': _fileMbSize,
                        },
                      ) :
                          const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
          widget.isShowWidget == false ?
            const SizedBox.shrink() :
              Container(
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

                        try {
                          await FirebaseUpload().uploadImageVideoInStorage(file: widget.video,type: "Videos",context: context,);
                          Get.off(const MyWorkTab(index: 1));
                        } catch (e) {
                          showSnackBar(context: context, isError: true, message: "Failed to Upload $e");
                        } finally {
                          setState(() { _isLoading = false; });
                        }
                       },
                    child: _isLoading ? const Center(child: CircularProgressIndicator()) : Text(
                      "Save",
                      style: TextStyle(
                        color: const CropGridStyle().selectedBoundariesColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

class CoverResultPopup extends StatefulWidget {
  const CoverResultPopup({super.key, required this.cover});

  final File cover;

  @override
  State<CoverResultPopup> createState() => _CoverResultPopupState();
}

class _CoverResultPopupState extends State<CoverResultPopup> {
  late final Uint8List _imagebytes = widget.cover.readAsBytesSync();
  Size? _fileDimension;
  late String _fileMbSize;

  @override
  void initState() {
    ThemeUtils.setStatusBarColor(const Color(0xff6EA9FF));
    super.initState();
    _getImageDimension(
      widget.cover,
      onResult: (d) => setState(() => _fileDimension = d),
    );
    _fileMbSize = _fileMBSize(widget.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(
                _imagebytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cover Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FileDescription(
                    description: {
                      'Cover path': widget.cover.path,
                      'Cover ratio': Fraction.fromDouble(_fileDimension?.aspectRatio ?? 0).reduce().toString(),
                      'Cover dimension': _fileDimension?.toString() ?? 'Unknown',
                      'Cover size': _fileMbSize,
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDescription extends StatelessWidget {
  const FileDescription({super.key, required this.description});

  final Map<String, String> description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: description.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: entry.value,
                        style: TextStyle(fontSize: 11,color: Colors.white.withOpacity(0.85),),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
