import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/core/model/song_model.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

import 'crop_page.dart';
import 'export_result.dart';
import 'export_services.dart';
import 'find_song.dart';

class VideoEditor extends StatefulWidget {
  final File file;
  File? audio;

  VideoEditor({super.key, required this.file, this.audio});

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> with ChangeNotifier {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;
  final AudioPlayer player = AudioPlayer();
  ValueNotifier<int> isSelectedPlayIndex = ValueNotifier(-1);
  ValueNotifier<bool> isMuted = ValueNotifier(true);
  FirebaseUpload firebaseUpload = FirebaseUpload();

  late final VideoEditorController _controller = VideoEditorController.file(
      widget.file,
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 30),
      coverThumbnailsQuality: 100,
      trimThumbnailsQuality: 100);

  @override
  void initState() {
    super.initState();
   /* _controller.initialize(aspectRatio: 9 / 16).then((_) {
      setState(() {});
      _controller.video.setVolume(1.0);
      isMuted.value = true;
    }).catchError((error) {
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);*/
    WidgetsBinding.instance.addPostFrameCallback((_){
      _controller.initialize(aspectRatio: 9 / 16).then((_) {
        setState(() {
          _controller.video.setVolume(1.0);
          if (widget.audio != null && widget.audio!.path.isNotEmpty) {
            player.setFilePath(widget.audio!.path).then((_) {
              player.play();
              isMuted.value = true;
            }).catchError((error) {
              print('Error setting file path: $error');
            });
          } else {
            print('Invalid audio path: ${widget.audio?.path}');
          }
        });
      }).catchError((error) {
        Navigator.pop(context);
        print('Error initializing video controller: $error');
      }, test: (e) => e is VideoMinDurationError);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Video Editor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _controller.initialized
          ? SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              Expanded(
                                child: TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CropGridViewer.preview(controller: _controller),
                                        AnimatedBuilder(
                                          animation: _controller.video,
                                          child: Container(color: Colors.white),
                                          builder: (_, __) => AnimatedOpacity(
                                            opacity: _controller.isPlaying ? 0 : 1,
                                            duration: kThemeAnimationDuration,
                                            child: GestureDetector(
                                              onTap: _controller.video.play,
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(color: Colors.black26,blurRadius: 8,offset: Offset(0, 4),),
                                                  ],
                                                ),
                                                child: const Icon(Icons.play_arrow,color: Colors.black,size: 30),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    CoverViewer(controller: _controller),
                                  ],
                                ),
                              ),
                              _topNavBar(),
                              Container(
                                height: 205,
                                margin: const EdgeInsets.only(top: 5),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const TabBar(
                                      tabs: [
                                        Padding(padding: EdgeInsets.all(5),child: Icon(Icons.content_cut)),
                                        Padding(padding: EdgeInsets.all(5),child: Icon(Icons.video_label)),
                                      ],
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        physics: const NeverScrollableScrollPhysics(),
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: _trimSlider(),
                                          ),
                                          _coverSelection(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: _isExporting,
                                builder: (_, bool export, Widget? child) {
                                  return AnimatedSize(
                                    duration: kThemeAnimationDuration,
                                    child: export
                                        ? AlertDialog(
                                            backgroundColor: const Color(0xff6EA9FF),
                                            title: ValueListenableBuilder(
                                              valueListenable: _exportingProgress,
                                              builder: (_, double value, __) =>
                                                  Center(
                                                    child: Text(
                                                      "Exporting video ${(value * 100).ceil()}%",
                                                      style: const TextStyle(color: Colors.black,fontSize: 16),
                                                ),
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() async {
    player.dispose();
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    ExportService.dispose();
    super.dispose();
  }

  ///   Export Video [_exportVideo]
  void _exportVideo() async {
    _isExporting.value = true;
    _exportingProgress.value = 0;

    final config = VideoFFmpegVideoEditorConfig(_controller);

    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        _exportingProgress.value = config.getFFmpegProgress(stats.getTime().round());
      },
      onError: (e, s) => showSnackBar(context: context, message: "Error on Export video"),
      onCompleted: (exportedFile) async {
        _isExporting.value = false;
        Get.to(VideoResultPopup(video: exportedFile,title: true,));
      },
    );
  }

  ///   Export Video [_exportCover]
  void _exportCover() async {
    final config = CoverFFmpegVideoEditorConfig(_controller);
    final execute = await config.getExecuteConfig();
    if (execute == null) {
      showSnackBar(
          context: context,
          message: ("Error on cover exportation initialization."));
      return;
    }

    await ExportService.runFFmpegCommand(
      execute,
      onError: (e, s) => showSnackBar(context: context, message: "Error on Export cover"),
      onCompleted: (cover) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => CoverResultPopup(cover: cover),
        );
      },
    );
  }

  ///   Rotate, Crop, Save, Volume Up Down
  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: 60, // Set a fixed height for better alignment
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute evenly
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: isMuted,
                builder: (context, value, child) {
                  return Tooltip(
                    message: 'Sound',
                    child: IconButton(
                      onPressed: () async {
                        isMuted.value = !isMuted.value;
                        await _controller.video.setVolume(value ? 0.0 : 1.0);
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          value ? Icons.volume_up : Icons.volume_off,
                          key: ValueKey<bool>(value),
                          size: 30, // Uniform icon size
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const VerticalDivider(endIndent: 16, indent: 16), // Adjusted spacing
            Expanded(
              child: Tooltip(
                message: 'Rotate UnClockwise',
                child: IconButton(
                  onPressed: () => _controller.rotate90Degrees(RotateDirection.left),
                  icon: const Icon(Icons.rotate_left, size: 30),
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: 'Open Crop Screen',
                child: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => CropPage(controller: _controller),
                    ),
                  ),
                  icon: const Icon(Icons.crop, size: 30),
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: 'Music',
                child: IconButton(
                  onPressed: () {
                    Duration duration = _controller.startTrim;
                    Duration duration1 = _controller.endTrim;
                    Duration totalDuration = calculateTotalDuration("$duration", "$duration1");
                    Get.to(FindSong(file: widget.file,duration: totalDuration));
                    },
                  icon: const Icon(Icons.music_note, size: 30),
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: 'Rotate Clockwise',
                child: IconButton(
                  onPressed: () => _controller.rotate90Degrees(RotateDirection.right),
                  icon: const Icon(Icons.rotate_right, size: 30),
                ),
              ),
            ),
            const VerticalDivider(endIndent: 16, indent: 16),
            Expanded(
              child: Tooltip(
                message: 'Open Export Menu',
                child: PopupMenuButton(
                  icon: const Icon(Icons.save, size: 30),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => _exportCover(),
                      child: const Text('Export Cover'),
                    ),
                    PopupMenuItem(
                      onTap: () => _exportVideo(),
                      child: const Text('Export Video'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration calculateTotalDuration(String duration1, String duration2) {
    Duration d1 = Duration(
      hours: int.parse(duration1.split(':')[0]),minutes: int.parse(duration1.split(':')[1]),
      seconds: int.parse(duration1.split(':')[2].split('.')[0]),
      microseconds: int.parse(duration1.split(':')[2].split('.')[1]),
    );
    Duration d2 = Duration(
      hours: int.parse(duration2.split(':')[0]),
      minutes: int.parse(duration2.split(':')[1]),
      seconds: int.parse(duration2.split(':')[2].split('.')[0]),
      microseconds: int.parse(duration2.split(':')[2].split('.')[1]),
    );
    Duration totalDuration = d2 - d1;
    return totalDuration;
  }

  ///   Formatter for length
  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  ///   Slider for trim Video
  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final int duration = _controller.videoDuration.inSeconds;
          final double pos = _controller.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(
              children: [
                Text(
                  formatter(Duration(seconds: pos.toInt())),
                  style: const TextStyle(fontWeight: FontWeight.bold), // Improved text visibility
                ),
                const Expanded(child: SizedBox()),
                AnimatedOpacity(
                  opacity: _controller.isTrimming ? 1 : 0,
                  duration: kThemeAnimationDuration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter(_controller.startTrim),
                        style: const TextStyle(color: Colors.black), // Consistent text color
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatter(_controller.endTrim),
                        style: const TextStyle(color: Colors.black), // Consistent text color
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      SizedBox(
        width: MediaQuery.of(context).size.width,
        child: TrimSlider(
          controller: _controller,
          scrollController: ScrollController(keepScrollOffset: true),
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      ),
    ];
  }

  ///Create Covers From Video [_coverSelection]
  Widget _coverSelection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _controller,
            size: height + 10,
            quantity: 6,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
