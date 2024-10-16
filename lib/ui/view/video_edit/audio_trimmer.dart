import 'dart:io';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioTrimmerViewDemo extends StatefulWidget {
  final Map<String, dynamic> song;

  const AudioTrimmerViewDemo({required this.song, super.key});

  @override
  State<AudioTrimmerViewDemo> createState() => _AudioTrimmerViewDemoState();
}

class _AudioTrimmerViewDemoState extends State<AudioTrimmerViewDemo> {
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 30.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;
  bool isLoading = false;
  Map<String, dynamic> data = {};
  final AudioPlayer _player = AudioPlayer();
  String? audioPath;

  @override
  void initState() {
    super.initState();
    data = widget.song;
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    setState(() {
      isLoading = true;
    });

    final Directory appDir = await getApplicationDocumentsDirectory();
    audioPath = '${appDir.path}/temp_audio.mp3';

    final http.Response response = await http.get(Uri.parse(data['url']));
    if (response.statusCode == 200) {
      final File audioFile = File(audioPath!);
      await audioFile.writeAsBytes(response.bodyBytes);

      await _trimmer.loadAudio(audioFile: audioFile);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      throw Exception('Failed to download audio');
    }
  }

  Future<void> _playPauseAudio() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.setFilePath(audioPath!);
      await _player.seek(Duration(seconds: _startValue.toInt())); // Use _startValue
      await _player.play();
      _player.positionStream.listen((position) {
        if (position.inSeconds >= _endValue) {
          _player.pause();
          setState(() => _isPlaying = false);
        }
      });
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _saveAudio() async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedAudio(
      startValue: _startValue,
      endValue: _endValue,
      audioFileName:
      'trimmed_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
      onSave: (outputPath) {
        if (mounted) {
          setState(() {
            _progressVisibility = false;
          });
        }
        debugPrint('OUTPUT PATH: $outputPath');
      },
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          isLoading
              ? const SizedBox.shrink()
              : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade50,
            ),
            onPressed: _progressVisibility ? null : () => _saveAudio(),
            child: const Text(
              "SAVE",
              style: TextStyle(color: Colors.lightBlueAccent),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Container(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Container(
                        width: 155,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.network(
                            data['artwork'],
                            height: 150,
                            width: 150,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data['artist']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data['title']),
                      )
                    ],
                  ),
                ),
                TrimViewer(
                  trimmer: _trimmer,
                  viewerHeight: 50,
                  viewerWidth: MediaQuery.of(context).size.width,
                  durationStyle: DurationStyle.FORMAT_MM_SS,
                  backgroundColor: Colors.teal,
                  maxAudioLength: const Duration(seconds: 30),
                  barColor: Colors.white,
                  showDuration: true,
                  durationTextStyle: const TextStyle(color: Colors.black),
                  allowAudioSelection: true,
                  paddingFraction: 2.0,
                  editorProperties: const TrimEditorProperties(
                    circleSize: 5.0,
                    circleSizeOnDrag: 8.0,
                    borderWidth: 3.0,
                    scrubberWidth: 1.0,
                    borderRadius: 4.0,
                    circlePaintColor: Colors.lightBlueAccent,
                    borderPaintColor: Colors.lightBlueAccent,
                    scrubberPaintColor: Colors.lightBlueAccent,
                    sideTapSize: 24,
                  ),
                  areaProperties: TrimAreaProperties.fixed(),
                  onChangeStart: (value) {
                    _startValue = value; // Update start value
                    debugPrint('Start Value: $_startValue');
                  },
                  onChangeEnd: (value) {
                    _endValue = value; // Update end value
                    debugPrint('End Value: $_endValue');
                  },
                  onChangePlaybackState: (value) {
                    setState(() => _isPlaying = value);
                  },
                ),
                TextButton(
                  onPressed: _playPauseAudio,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 80.0,
                    color: Colors.teal,
                  ),
                ),
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
