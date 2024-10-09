import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:videoapp/ui/view/preview.dart';

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {super.key});

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  Future<void> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) {
        setState(() {
          _progressVisibility = false;
        });
        if (outputPath != null) {
          debugPrint('OUTPUT PATH: $outputPath');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Preview(outputPath),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xff6EA9FF),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Trim Video",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _progressVisibility ? null : () => _saveVideo(),
              tooltip: 'Save Video',
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_progressVisibility)
              const LinearProgressIndicator(
                backgroundColor: Colors.red,
                minHeight: 5,
              ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: VideoViewer(trimmer: _trimmer),
                  ),
                  const SizedBox(height: 20.0),
                  Expanded(
                    flex: 2,
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      durationStyle: DurationStyle.FORMAT_MM_SS,
                      maxVideoLength: const Duration(seconds: 30),
                      editorProperties: TrimEditorProperties(
                        borderPaintColor: Colors.teal,
                        borderWidth: 3,
                        borderRadius: 8,
                        circlePaintColor: Colors.teal.shade700,
                      ),
                      durationTextStyle: const TextStyle(color: Colors.black),
                      areaProperties: TrimAreaProperties.edgeBlur(
                        thumbnailQuality: 10,
                      ),
                      onChangeStart: (value) => setState(() {
                        _startValue = value;
                      }),
                      onChangeEnd: (value) => setState(() {
                        _endValue = value;
                      }),
                      onChangePlaybackState: (isPlaying) {
                        setState(() {
                          _isPlaying = isPlaying;
                        });
                      },
                      showDuration: true,
                      type: ViewerType.auto,
                      paddingFraction: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: IconButton(
                      iconSize: 50.0,
                      color: Colors.black,
                      icon: _isPlaying ? const Icon(Icons.pause_circle_filled) : const Icon(Icons.play_circle_filled),
                      onPressed: () async {
                        bool playbackState = await _trimmer.videoPlaybackControl(
                          startValue: _startValue,
                          endValue: _endValue,
                        );
                        setState(() {
                          _isPlaying = playbackState;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
