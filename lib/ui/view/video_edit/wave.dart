import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:videoapp/core/model/song_model.dart';

class WaveAudio extends StatefulWidget {
  final Song song;
  final File file;
  final Duration duration;

  const WaveAudio(
      {required this.song,
      super.key,
      required this.file,
      required this.duration});

  @override
  State<WaveAudio> createState() => _WaveAudioState();
}

class _WaveAudioState extends State<WaveAudio> {
  final Trimmer _trimmer = Trimmer();
  bool _progressVisibility = false;
  bool isLoading = false;
  Song? data;
  final AudioPlayer _player = AudioPlayer();
  String audioPath = "";

  double startValue = 0.0;
  double endValue = 30.0;
  Duration totalDuration = Duration.zero;

  double _containerPosition = 0;
  double _containerWidth = 30;
  double _minPosition = 0.0;
  double _maxPosition = 300.0;

  final PlayerController controller =
      PlayerController(); // Controller for waveform

  @override
  void initState() {
    data = widget.song;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _loadAudio();
        _maxPosition = Get.width - 26;
      },
    );
  }

  Future<void> _loadAudio() async {
    setState(() {
      isLoading = true;
    });

    await controller.preparePlayer(
        path: widget.file.path, // Set the URL as the audio source
        shouldExtractWaveform: true,
        volume: 1.0 // This flag extracts the waveform
        );

    controller.addListener(() async {
      int duration = await controller.getDuration();
      if (duration == controller.maxDuration) {
        controller.seekTo(0);
      }
      int startPosition = 1000;
      int endPosition = 30000;
      // if(duration > _containerPosition) {
      //   double persent = 100 * _containerPosition / Get.width;
      //   int totalmilis = controller.maxDuration;
      //   double currentmilis = totalmilis * persent / 100;
      //   print(currentmilis);
      //   // controller.pausePlayer();
      //   controller.seekTo(currentmilis.toInt());
      // }
      if (duration > _containerPosition) {
        double percent = 100 * _containerPosition / Get.width;
        int totalMillis = controller.maxDuration;
        double currentMillis = totalMillis * percent;

        print(currentMillis);

        if (currentMillis >= endPosition) {
          // If the current position exceeds the end of the range, reset to the start of the range
          controller.seekTo(startPosition);
        } else if (currentMillis < startPosition) {
          // Ensure the playback doesn't start before the range
          controller.seekTo(startPosition);
        } else {
          // Normal playback within the range
          controller.seekTo(currentMillis.toInt());
        }
      }
    });

    controller.startPlayer();
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    if (_trimmer.audioPlayer != null) {
      _trimmer.audioPlayer!.pause();
      _trimmer.audioPlayer!.dispose();
    }
    controller.dispose();
    _player.dispose();
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
          isLoading
              ? const SizedBox.shrink()
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade50,
                  ),
                  onPressed: () {},
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
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 60,
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: Get.width - 50,
                              child: AudioFileWaveforms(
                                size: Size(
                                    MediaQuery.of(context).size.width - 20,
                                    200),
                                playerController: controller,
                                waveformType: WaveformType.long,
                                // Set the waveform type
                                enableSeekGesture: true,
                                animationDuration:
                                    const Duration(milliseconds: 100),
                                continuousWaveform: true,
                                // Enables seek on waveform tap
                                playerWaveStyle: const PlayerWaveStyle(
                                  scaleFactor: 60,
                                  fixedWaveColor: Colors.black,
                                  liveWaveColor: Colors.blueAccent,
                                  waveCap: StrokeCap.round,
                                ),
                              ),
                            ),
                            Positioned(
                              left: (Get.width - _containerWidth - 26) / 2,
                              child: Container(
                                height: 54,
                                width: _containerWidth,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
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
