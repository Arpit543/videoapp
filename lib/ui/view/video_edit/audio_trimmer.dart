import 'dart:io';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';

class AudioTrimmerViewDemo extends StatefulWidget {
  final Map<String, dynamic> song;
  final File file;

  const AudioTrimmerViewDemo({required this.song, super.key, required this.file});

  @override
  State<AudioTrimmerViewDemo> createState() => _AudioTrimmerViewDemoState();
}

class _AudioTrimmerViewDemoState extends State<AudioTrimmerViewDemo> {
  final Trimmer _trimmer = Trimmer();
  bool isPlaying = false;
  ValueNotifier<bool> isPlay = ValueNotifier<bool>(false);
  bool _progressVisibility = false;
  bool isLoading = false;
  Map<String, dynamic> data = {};
  final AudioPlayer _player = AudioPlayer();
  String? audioPath;

  double startValue = 0.0;
  double endValue = 30.0;

  Duration totalDuration = const Duration(seconds: 120);
  Duration startDuration = Duration.zero;
  Duration endDuration = const Duration(seconds: 320);

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
      print("audioFile :- $audioFile");
      await _trimmer.loadAudio(audioFile: audioFile);
      await _trimmer.audioPlayer!.getDuration();
      await _trimmer.audioPlayer!.getCurrentPosition();
      setState(() {
        isLoading = false;
      });
    } else {
      throw Exception('Failed to download audio');
    }
  }

  Future<void> _saveAudio() async {
    setState(() {
      _progressVisibility = true;
    });

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String outputPath = '${appDir.path}/trimmed_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

    final String command = '-i "$audioPath" -ss $startValue -to $endValue -c copy "$outputPath"';

    FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        print("Success");
        setState(() {
          _progressVisibility = false;
        });
        Navigator.push(context,MaterialPageRoute(builder: (context) => VideoEditor(audio: File(outputPath), file: widget.file),),);
      } else {
        print("Failed");
        setState(() {
          _progressVisibility = false;
        });
      }
    });
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
          isLoading ? const SizedBox.shrink() :
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade50,
            ),
            onPressed: _progressVisibility ? null : _saveAudio,
            child: const Text(
              "SAVE",
              style: TextStyle(color: Colors.lightBlueAccent),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) :
      SingleChildScrollView(
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
                      ),
                    ],
                  ),
                ),
                TrimViewer(
                  trimmer: _trimmer,
                  viewerHeight: 50,
                  viewerWidth: MediaQuery.of(context).size.width,
                  durationStyle: DurationStyle.FORMAT_MM_SS,
                  backgroundColor: Colors.teal,
                  barColor: Colors.yellow,
                  showDuration: true,
                  maxAudioLength: const Duration(seconds: 30),
                  editorProperties: const TrimEditorProperties(
                    circleSize: 5.0,
                    circleSizeOnDrag: 8.0,
                    borderWidth: 3.0,
                    scrubberWidth: 1.0,
                    borderRadius: 4.0,
                    circlePaintColor: Colors.lightBlueAccent,
                    borderPaintColor: Colors.lightBlueAccent,
                    scrubberPaintColor: Colors.lightBlueAccent,
                    sideTapSize: 10,
                  ),
                  durationTextStyle: const TextStyle(color: Colors.black),
                  allowAudioSelection: true,
                  paddingFraction: 2.0,
                  areaProperties: const FixedTrimAreaProperties(),
                  onChangeStart: (value) {
                    debugPrint('Change Start Triggered: $value');
                    setState(() {
                      startValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    debugPrint('Change End Triggered: $value');
                    setState(() {
                      endValue = value;
                    });
                  },
                  onChangePlaybackState: (value) {
                    if (mounted) {
                      setState(() => isPlaying = value);
                    }
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isPlay,
                  builder: (context, isPlaying, _) {
                    return IconButton(
                      iconSize: 50,
                      onPressed: () async {
                        try {
                          if (isPlaying) {
                            await _trimmer.audioPlayer?.pause();
                            isPlay.value = false;
                          } else {
                            isPlay.value = true;
                            await _trimmer.audioPlaybackControl(startValue: startValue, endValue: endValue);
                          }
                        } catch (e) {
                          print('Error: $e');
                        }
                      },
                      icon: isPlaying ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                    );
                  },
                ),
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Duration?> d () {
    print("Duration :- ${_trimmer.audioPlayer!.getDuration()}");
    return _trimmer.audioPlayer!.getDuration();
  }
}

