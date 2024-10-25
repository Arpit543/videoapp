import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:videoapp/core/model/song_model.dart';

class AudioTrimmerViewDemo extends StatefulWidget {
  final Song song;
  final File audioFileForTrim;
  final bool isImage;
  final Function(String file) audioFile;

  const AudioTrimmerViewDemo({required this.song, super.key, required this.audioFileForTrim, required this.audioFile, required this.isImage});

  @override
  State<AudioTrimmerViewDemo> createState() => _AudioTrimmerViewDemoState();
}

class _AudioTrimmerViewDemoState extends State<AudioTrimmerViewDemo> {
  final Trimmer _trimmer = Trimmer();

  bool _progressVisibility = false;
  bool isLoading = false;
  late Song? data;
  String audioPath = "";

  double startValue = 0.0;
  double endValue = 0.0;


  @override
  void initState() {
    data = widget.song;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadAudio();
    },);
  }

  void _loadAudio() async {
    setState(() {
      isLoading = true;
    });
    await _trimmer.loadAudio(audioFile: widget.audioFileForTrim);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveAudio(BuildContext context) async {
    setState(() {
      _progressVisibility = true;
    });

    final Directory? externalDir = await getExternalStorageDirectory();
    final String basePath = '${externalDir?.parent.parent.parent.parent.path}/Download/';

    if (externalDir == null || !await Directory(basePath).exists()) {
      setState(() {
        _progressVisibility = false;
      });
      Get.snackbar("Error", "External storage not available.");
      return;
    }

    _trimmer.saveTrimmedAudio(
      startValue: startValue,
      endValue: endValue,
      audioFileName: DateTime.now().millisecondsSinceEpoch.toString(),
      onSave: (outputPath) {
        if (outputPath == null || outputPath.isEmpty) {
          setState(() {
            _progressVisibility = false;
          });
          Get.snackbar("Error", "Failed to trim audio.");
          return "";
        }

        debugPrint('OUTPUT PATH: $outputPath');

        final File trimmedAudioFile = File(outputPath);
        if (!trimmedAudioFile.existsSync()) {
          setState(() {
            _progressVisibility = false;
          });
          Get.snackbar("Error", "Trimmed audio file not found.");
          return "";
        }

        setState(() {
          _progressVisibility = false;
        });

        widget.audioFile(trimmedAudioFile.path);
        Navigator.pop(context);
      },
    );
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
        automaticallyImplyLeading: false,
        leading: InkWell(
            onTap: () {
              Get.back();
              _trimmer.audioPlayer!.pause();
              _trimmer.audioPlayer!.dispose();
            },
            child: const Icon(Icons.arrow_back,color: Colors.black,),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          isLoading ? const SizedBox.shrink() :
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade50,
            ),
            onPressed: _progressVisibility ? null : () {
              _saveAudio(context);
            },
            child: const Text(
              "SAVE",
              style: TextStyle(color: Colors.lightBlueAccent),
            ),
          ),
        ],
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) :
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
                    setState(() {
                      startValue = value;
                    });

                    _trimmer.audioPlaybackControl(startValue: startValue, endValue: endValue);
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      endValue = value;
                    });

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
