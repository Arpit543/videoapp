import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/home_screen.dart';

Future<void> _getImageDimension(File file,
    {required Function(Size) onResult}) async {
  var decodedImage = await decodeImageFromList(file.readAsBytesSync());
  onResult(Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()));
}

String _fileMBSize(File file) =>
    ' ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB';

/// Class to show Video after edit [VideoResultPopup]
class VideoResultPopup extends StatefulWidget {
  final File video;
  final bool title;

  const VideoResultPopup({super.key, required this.video, required this.title});

  @override
  State<VideoResultPopup> createState() => _VideoResultPopupState();
}

class _VideoResultPopupState extends State<VideoResultPopup> {
  VideoPlayerController? _controller;
  FileImage? _fileImage;
  Size _fileDimension = Size.zero;
  late final bool _isGif =
      path.extension(widget.video.path).toLowerCase() == ".gif";
  late String _fileMbSize;
  FirebaseUpload firebaseUpload = FirebaseUpload();

  @override
  void initState() {
    super.initState();
    if (_isGif) {
      _getImageDimension(
        widget.video,
        onResult: (d) => setState(() => _fileDimension = d),
      );
    } else {
      _controller = VideoPlayerController.file(widget.video);
      _controller?.initialize().then((_) {
        _fileDimension = _controller?.value.size ?? Size.zero;
        setState(() {});
        _controller?.play();
        _controller?.setLooping(true);
      });
    }
    _fileMbSize = _fileMBSize(widget.video);
  }

  @override
  void dispose() {
    if (_isGif) {
      _fileImage?.evict();
    } else {
      _controller?.pause();
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xff6EA9FF),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(
            widget.title ? "Edited Video" : "",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  AspectRatio(
                    aspectRatio: _fileDimension.aspectRatio != 0
                        ? _fileDimension.aspectRatio
                        : 1,
                    child: _isGif
                        ? Image.file(widget.video, fit: BoxFit.cover)
                        : SizedBox(
                      height: MediaQuery.of(context).size.height,
                        child: VideoPlayer(_controller!)),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: widget.title
                        ? FileDescription(
                            description: {
                              if (!_isGif)
                                'Video duration':
                                    '${((_controller?.value.duration.inMilliseconds ?? 0) / 1000).toStringAsFixed(2)}s',
                              'Video ratio': Fraction.fromDouble(
                                      _fileDimension.aspectRatio)
                                  .reduce()
                                  .toString(),
                              'Video dimension': _fileDimension.toString(),
                              'Video size': _fileMbSize,
                            },
                          )
                        : const SizedBox(
                            height: 10,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.title
            ? Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xff6EA9FF),
                      blurRadius: 8,
                      offset: Offset(0, -2), // Adjust shadow for better effect
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
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: () {
                          firebaseUpload.uploadFileInStorage(
                            file: widget.video,
                            type: "Videos",
                            context: context,
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        child: Text(
                          "Save",
                          style: TextStyle(
                            color:
                                const CropGridStyle().selectedBoundariesColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(height: 50),
      ),
    );
  }
}

/// Class to show Cover Image from image and video [CoverResultPopup]
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
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(15)),
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
                      'Cover ratio':
                          Fraction.fromDouble(_fileDimension?.aspectRatio ?? 0)
                              .reduce()
                              .toString(),
                      'Cover dimension':
                          _fileDimension?.toString() ?? 'Unknown',
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

/// Show File Description When Video or Image file Exported
class FileDescription extends StatelessWidget {
  const FileDescription({super.key, required this.description});

  final Map<String, String> description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7), // Slightly darker for contrast
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),
      child: ListView(
        shrinkWrap: true,
        // Allows the ListView to take only the needed space
        physics: const NeverScrollableScrollPhysics(),
        // Disable scrolling for smooth integration
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
                          fontWeight: FontWeight.bold, // Bold for keys
                          color: Colors.white, // Ensure visibility
                        ),
                      ),
                      TextSpan(
                        text: entry.value,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(
                              0.85), // Slightly higher opacity for value
                        ),
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
