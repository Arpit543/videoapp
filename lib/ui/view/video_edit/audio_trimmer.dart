import 'dart:io';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:videoapp/core/model/song_model.dart';
import 'package:videoapp/ui/view/video_edit/video_editor.dart';

class AudioTrimmerViewDemo extends StatefulWidget {
  final Song song;
  final File file;
  final Duration duration;

  const AudioTrimmerViewDemo({required this.song, super.key, required this.file, required this.duration});

  @override
  State<AudioTrimmerViewDemo> createState() => _AudioTrimmerViewDemoState();
}

class _AudioTrimmerViewDemoState extends State<AudioTrimmerViewDemo> {
  final Trimmer _trimmer = Trimmer();
  bool _progressVisibility = false;
  bool isLoading = false;
  Song? data;
  final AudioPlayer _player = AudioPlayer();
  String audioPath = "";

  double startValue = 0.0;
  double endValue = 30.0;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    data = widget.song;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadAudio();
    },);
  }

  Future<void> _loadAudio() async {
    setState(() {
      isLoading = true;
    });
    print("Artwork : ${data!.artwork}");
      await _trimmer.loadAudio(audioFile: widget.file);

      // Get the total duration
      Duration? duration = await _trimmer.audioPlayer!.getDuration();
      print("Total Duration: ${duration?.inSeconds} seconds");

      startValue = 0.0;
      endValue = 30;//(duration!.inSeconds > widget.duration.inSeconds ? startValue + widget.duration.inSeconds : duration!.inSeconds).toDouble();
      setState(() {
        totalDuration = duration!;
        endValue = totalDuration.inSeconds.toDouble(); // Set endValue to total duration
        isLoading = false;
      });

      // Start playing the audio as soon as it's loaded
      await _trimmer.audioPlaybackControl(startValue: startValue, endValue: endValue);
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
      } else {
        print("Failed to trim audio");
      }
      setState(() {
        _progressVisibility = false;
      });
    });
  }

  @override
  void dispose() {
    if(_trimmer.audioPlayer != null) {
      _trimmer.audioPlayer!.pause();
      _trimmer.audioPlayer!.dispose();
    }
    _trimmer.dispose();
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
                            data!.artwork,
                            height: 150,
                            width: 150,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data!.artist),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data!.title),
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
                  maxAudioLength: const Duration(seconds: 60),
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
                    setState(() {
                      // value is a percentage (0 to 100), so we scale it to totalDuration
                      startValue = (value / 100) * totalDuration.inSeconds;
                      print("Start Value: $startValue");
                    });

                    // Restart audio playback from updated startValue
                    _trimmer.audioPlaybackControl(startValue: startValue, endValue: endValue);
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      // value is a percentage (0 to 100), so we scale it to totalDuration
                      endValue = (value / 100) * totalDuration.inSeconds;
                      print("End Value: $endValue");
                    });

                    // Restart audio playback from updated startValue
                    _trimmer.audioPlaybackControl(startValue: startValue, endValue: endValue);
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
}
