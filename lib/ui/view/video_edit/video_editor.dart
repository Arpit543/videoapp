import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/core/model/song_model.dart';
import 'package:http/http.dart' as http;
import 'package:videoapp/ui/view/video_edit/audio_trimmer.dart';
import 'crop_page.dart';
import 'export_result.dart';
import 'export_services.dart';

class VideoEditor extends StatefulWidget {
  final File file;

  const VideoEditor({super.key, required this.file});

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> with ChangeNotifier {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;
  final AudioPlayer player = AudioPlayer();
  ValueNotifier<int> isSelectedPlayIndex = ValueNotifier(-1);
  ValueNotifier<bool> isMuted = ValueNotifier(false);
  FirebaseUpload firebaseUpload = FirebaseUpload();

  late final VideoEditorController _controller = VideoEditorController.file(
      widget.file,
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 30),
      coverThumbnailsQuality: 100,
      trimThumbnailsQuality: 100);

  @override
  void initState() {
    fetchSongs();
    super.initState();
    _controller.initialize(aspectRatio: 9 / 16).then((_) {
      setState(() {});
      _controller.video.setVolume(1.0);
      isMuted.value = true;
    }).catchError((error) {
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
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
                                          child: Container(color: Colors.white,),
                                          builder: (_, __) => AnimatedOpacity(
                                            opacity: _controller.isPlaying ? 0 : 1,
                                            duration: kThemeAnimationDuration,
                                            child: GestureDetector(
                                              onTap: _controller.video.play,
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(color: Colors.white,shape: BoxShape.circle),
                                                child: const Icon(Icons.play_arrow,color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    CoverViewer(controller: _controller)
                                  ],
                                ),
                              ),
                              _topNavBar(),
                              Container(
                                height: 205,
                                margin: const EdgeInsets.only(top: 5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          //_filterOption(),
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
                                    child: export ? child : null,
                                  );
                                },
                                child: AlertDialog(
                                  backgroundColor: const Color(0xff6EA9FF),
                                  title: ValueListenableBuilder(
                                    valueListenable: _exportingProgress,
                                    builder: (_, double value, __) => Center(
                                      child: Text(
                                        "Exporting video ${(value * 100).ceil()}%",
                                        style: const TextStyle(color: Colors.black, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() async {
    super.dispose();
    player.dispose();
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    ExportService.dispose();
  }

  ///   Show Error SnackBar
  void _showErrorSnackBar(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message),duration: const Duration(seconds: 1),),);

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
      onError: (e, s) => _showErrorSnackBar("Error on export video :("),
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
      _showErrorSnackBar("Error on cover exportation initialization.");
      return;
    }

    await ExportService.runFFmpegCommand(
      execute,
      onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
      onCompleted: (cover) {
        if (!mounted) return;
        showDialog(context: context,builder: (_) => CoverResultPopup(cover: cover),);
      },
    );
  }

  ///   Rotate, Crop, Save, Volume Up Down
  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: isMuted,
                builder: (context, value, child) {
                  return IconButton(
                    onPressed: () async {
                      isMuted.value = !isMuted.value;
                      await _controller.video.setVolume(value ? 0.0 : 1.0);
                    },
                    icon: isMuted.value == false ? const Icon(Icons.volume_off) : const Icon(Icons.volume_up),
                    tooltip: 'Sound',
                  );
                },
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: IconButton(
                onPressed: () => _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left),
                tooltip: 'Rotate unClockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute<void>(builder: (context) => CropPage(controller: _controller),),),
                icon: const Icon(Icons.crop),
                tooltip: 'Open crop screen',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => _showMusicBottomSheet(context),
                icon: const Icon(Icons.music_note),
                tooltip: 'Music',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right),
                tooltip: 'Rotate clockwise',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: PopupMenuButton(
                tooltip: 'Open export menu',
                icon: const Icon(Icons.save),
                itemBuilder: (context) => [
                  PopupMenuItem(onTap: () => _exportCover(),child: const Text('Export cover'),),
                  PopupMenuItem(onTap: () => _exportVideo(),child: const Text('Export video'),),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            child: Row(children: [
              Text(formatter(Duration(seconds: pos.toInt()))),
              const Expanded(child: SizedBox()),
              AnimatedOpacity(
                opacity: _controller.isTrimming ? 1 : 0,
                duration: kThemeAnimationDuration,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatter(_controller.startTrim)),
                  const SizedBox(width: 10),
                  Text(formatter(_controller.endTrim)),
                ]),
              ),
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
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
      )
    ];
  }

  ///   To get Song from URL [fetchSongs]
  Future<List<Song>> fetchSongs() async {
    final String response =
        await rootBundle.loadString('assets/json/music.json');
    final List<dynamic> jsonList = jsonDecode(response);
    return jsonList.map((json) => Song.fromJson(json)).toList();
  }

  ///   Merge Audio and Video [mergeAudioAndVideo]
  Future<String> mergeAudioAndVideo(String videoPath, String audioUrl) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String audioPath = '${appDir.path}/temp_audio.mp3';

      final http.Response response = await http.get(Uri.parse(audioUrl));
      if (response.statusCode == 200) {
        final File audioFile = File(audioPath);
        await audioFile.writeAsBytes(response.bodyBytes);
        print("Audio File :- ${audioFile.writeAsBytes(response.bodyBytes)}");
      } else {
        throw Exception('Failed to download audio');
      }

      final Directory? externalDir = await getExternalStorageDirectory();
      final String basePath = '${externalDir?.parent.parent.parent.parent.path}/Download/';

      String outputPath = getUniqueFilePath(basePath, "output", "mp4");

      final File videoFile = File(videoPath);
      final File audioFile = File(audioPath);

      if (!await videoFile.exists()) {
        throw Exception('Video file does not exist at: $videoPath');
      }
      if (!await audioFile.exists()) {
        throw Exception('Audio file does not exist at: $audioPath');
      }

      print("Video Path: $videoPath");
      print("Audio Path: $audioPath");
      print("Output Path: $outputPath");

      final String command = "-y -i $videoPath -i $audioPath -map 0:v -map 1:a -c:v copy -shortest $outputPath";

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        final log = await session.getAllLogs();
        log.forEach((log) {
          print(log.getMessage());
        });

        if (ReturnCode.isSuccess(returnCode)) {
          return outputPath;
        } else if (ReturnCode.isCancel(returnCode)) {
          throw Exception('FFmpeg command was canceled');
        } else {
          throw Exception('FFmpeg command failed');
        }
      });

      print("Output Path: $outputPath");
      return outputPath;
    } catch (e) {
      throw Exception('Error merging audio and video: $e');
    }
  }

  String getUniqueFilePath(String basePath, String fileName, String extension) {
    int count = 0;
    String fullPath = '$basePath$fileName.$extension';

    while (File(fullPath).existsSync()) {
      count++;
      fullPath = '$basePath$fileName$count.$extension';
    }

    return fullPath;
  }

  ///   Show Music Bottom Sheet
  void _showMusicBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: _musicList(),
          ),
        );
      },
    );
  }

  ///   Show Music List
  Widget _musicList() {
    return FutureBuilder<List<Song>>(
      future: fetchSongs(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final song = snapshot.data![index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () async {
                    String videoPath = widget.file.path;
                    String audioUrl = song.url;

                    /*print("Audio $audioUrl");
                    mergeAudioAndVideo(videoPath, audioUrl).then((outputPath) {
                      print('Merged video saved at $outputPath');
                    }).catchError((error) {
                      print('Error: $error');
                    });*/

                    print("Call");
                    downloadAndTrimAudio(audioUrl, context);
                    print("Called");
                    //Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  song.artwork,
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    song.artist,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ValueListenableBuilder(
                            valueListenable: isSelectedPlayIndex,
                            builder: (context, indexValue, _) {
                              return IconButton(
                                onPressed: () async {
                                  if (indexValue == index) {
                                    isSelectedPlayIndex.value = -1;
                                    Future.delayed(const Duration(milliseconds: 300),() async => await player.pause());
                                  } else {
                                    isSelectedPlayIndex.value = index;
                                    await player.setAudioSource(AudioSource.uri(Uri.parse(song.url)));
                                    await player.play();
                                  }
                                },
                                icon: indexValue == index ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }


  Future<void> downloadAndTrimAudio(String url, BuildContext context) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String audioPath = '${appDir.path}/temp_audio.mp3';

      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final File audioFile = File(audioPath);
        await audioFile.writeAsBytes(response.bodyBytes);
        print("Audio File saved at: $audioPath");

        Navigator.push(context, MaterialPageRoute(builder: (context) => AudioTrimmerView(file: audioFile),));
      } else {
        throw Exception('Failed to download audio');
      }
    } catch(e) {
      print("Error : ${e.toString()}");
    }
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
