import 'dart:io';

import 'package:easy_audio_trimmer/easy_audio_trimmer.dart' as trim;
import 'package:flutter/material.dart';

class AudioTrimmerView extends StatefulWidget {
  final File file;

  const AudioTrimmerView({required this.file, super.key});

  @override
  State<AudioTrimmerView> createState() => _AudioTrimmerViewState();
}

class _AudioTrimmerViewState extends State<AudioTrimmerView> {
  late trim.Trimmer _trimmer;

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;
  bool isLoading = false;

  @override
  void initState() {
    _trimmer = trim.Trimmer();
    super.initState();
    _loadAudio();
  }

  void _loadAudio() async {
    setState(() {
      isLoading = true;
    });
    await _trimmer.loadAudio(audioFile: widget.file);
    setState(() {
      isLoading = false;
    });
  }

  _saveAudio() {
    setState(() {
      _progressVisibility = true;
    });

    _trimmer.saveTrimmedAudio(
      startValue: _startValue,
      endValue: _endValue,
      audioFileName: DateTime.now().millisecondsSinceEpoch.toString(),
      onSave: (outputPath) {
        setState(() {
          _progressVisibility = false;
        });
        debugPrint('OUTPUT PATH: $outputPath');
      },
    );
  }

  @override
  void dispose() {
    if (mounted) {
      _trimmer.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Audio Trimmer"),
      ),
      body: Center(
              child: Container(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Visibility(
                      visible: _progressVisibility,
                      child: LinearProgressIndicator(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _progressVisibility ? null : () => _saveAudio(),
                      child: const Text("SAVE"),
                    ),
                    SizedBox(
                      height: 250,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: trim.TrimViewer(
                            trimmer: _trimmer,
                            viewerHeight: 100,
                            maxAudioLength: const Duration(seconds: 50),
                            viewerWidth: MediaQuery.of(context).size.width,
                            durationStyle: trim.DurationStyle.FORMAT_MM_SS,
                            backgroundColor: Theme.of(context).primaryColor,
                            barColor: Colors.white,
                            durationTextStyle: TextStyle(color: Theme.of(context).primaryColor),
                            allowAudioSelection: true,
                            editorProperties: trim.TrimEditorProperties(circleSize: 10,borderPaintColor: Colors.yellowAccent,borderWidth: 4,borderRadius: 5,circlePaintColor: Colors.yellow.shade400),
                            areaProperties: trim.TrimAreaProperties.edgeBlur(blurEdges: true),
                            onChangeStart: (value) => _startValue = value,
                            onChangeEnd: (value) => _endValue = value,
                            onChangePlaybackState: (value) {
                              if (mounted) {
                                setState(() => _isPlaying = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      child: _isPlaying
                          ? Icon(Icons.pause,size: 80.0,color: Theme.of(context).primaryColor,)
                          : Icon(Icons.play_arrow,size: 80.0,color: Theme.of(context).primaryColor,),
                      onPressed: () async {
                        bool playbackState = await _trimmer.audioPlaybackControl(startValue: _startValue,endValue: _endValue,);
                        setState(() => _isPlaying = playbackState);
                      },
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
