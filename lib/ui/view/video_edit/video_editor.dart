import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:videoapp/ui/view/video_edit/crop_page.dart';
import 'package:videoapp/ui/view/video_edit/export_result.dart';
import 'package:videoapp/ui/view/video_edit/export_services.dart';
import 'package:videoapp/ui/view/video_edit/find_song.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

import '../../widget/common_theme.dart';

class VideoEditor extends StatefulWidget {
  final File videoFileForEditing;
  final bool navigateForIsStory;
  final Function(String file) videoFileForEditingFunction;

  const VideoEditor({super.key, required this.videoFileForEditing, required this.videoFileForEditingFunction,required this.navigateForIsStory});

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> with ChangeNotifier {

  ///   Export Cover [_exportCover]
  ///   Export Edited Video [_exportAndMergeVideo]
  ///   Rotate, Crop, Music, Save, Volume [volumeRotateCropMusicExport]
  ///   Formatter for length [formatter]
  ///   Slider for trim Video [trimmerViewForVideo]
  ///  Create Covers From Video [_coverSelection]
  ///   Merge Audio and Video [mergeAudioAndVideo]
  ///   Initialize VideoEditorController [_videoEditorController]

  File? _audioFile;
  bool _isLoading = false;
  final _isMuted = ValueNotifier(true);
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final _height = 60.0;
  final AudioPlayer _player = AudioPlayer();
  late String _exportFilePath = "";

  late final VideoEditorController _videoEditorController = VideoEditorController.file(
    widget.videoFileForEditing,
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 30),
    coverThumbnailsQuality: 100,
    trimStyle: const TrimSliderStyle(
        iconSize: 14,
        positionLineColor: Colors.cyanAccent,
        iconColor: Colors.white,
        edgesSize: 6,
        onTrimmingColor: Color(0xff6EA9FF),
        onTrimmedColor: Colors.cyan,
        borderRadius: BorderSide.strokeAlignOutside,
        edgesType: TrimSliderEdgesType.circle),
    trimThumbnailsQuality: 100,
  );

  @override
  void initState() {
    ThemeUtils.setStatusBarColor(const Color(0xff6EA9FF));
    _initializeController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _videoEditorController.initialized
          ? SafeArea(
              child: Stack(
                children: [
                  if (_isLoading) const Center(child: CircularProgressIndicator(),),
                  Column(
                    children: [
                      volumeRotateCropMusicExport(),
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
                                      fit: StackFit.loose,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: _videoEditorController.video.value.aspectRatio,
                                          child: CropGridViewer.preview(controller: _videoEditorController),
                                        ),
                                        AnimatedBuilder(
                                          animation: _videoEditorController.video,
                                          child: Container(color: Colors.white),
                                          builder: (_, __) => AnimatedOpacity(
                                            opacity: _videoEditorController.isPlaying ? 0 : 1,
                                            duration: kThemeAnimationDuration,
                                            child: GestureDetector(
                                              onTap: _videoEditorController.video.play,
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 8,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.black,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    CoverViewer(controller: _videoEditorController),
                                  ],
                                ),
                              ),
                              Container(
                                height: 205,
                                margin: const EdgeInsets.only(top: 5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const TabBar(
                                      tabs: [
                                        Padding( padding: EdgeInsets.all(5), child: Icon(Icons.content_cut,color: Colors.black),),
                                        Padding( padding: EdgeInsets.all(5), child: Icon(Icons.video_label,color: Colors.black),),
                                      ],
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        physics: const NeverScrollableScrollPhysics(),
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: trimmerViewForVideo(),
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
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16),
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
  void dispose() {
    _player.pause();
    _player.dispose();
    _videoEditorController.video.pause();
    _videoEditorController.video.dispose();
    _videoEditorController.dispose();
    _isExporting.dispose();
    _exportingProgress.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    try {
      await _videoEditorController.initialize(aspectRatio: 16 / 9);
      setState(() {});
      _videoEditorController.video.setVolume(1.0);
      _isMuted.value = true;
    } catch (error) {
      if (error is VideoMinDurationError) {
        Get.back();
      } else {
        debugPrint("Error initializing video: $error");
      }
    }
  }

  Widget volumeRotateCropMusicExport() {
    return SafeArea(
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _isMuted,
                builder: (context, value, child) {
                  return Tooltip(
                    message: 'Sound',
                    child: IconButton(
                      onPressed: () async {
                        _isMuted.value = !_isMuted.value;
                        await _videoEditorController.video.setVolume(value ? 0.0 : 1.0);
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          value ? Icons.volume_up : Icons.volume_off,
                          key: ValueKey<bool>(value),
                          color: Colors.black,
                          size: 30, // Uniform icon size
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const VerticalDivider(endIndent: 16, indent: 16),
            // Adjusted spacing
            Expanded(
              child: Tooltip(
                message: 'Rotate UnClockwise',
                child: IconButton(
                  onPressed: () =>
                      _videoEditorController.rotate90Degrees(RotateDirection.left),
                  icon: const Icon(
                    Icons.rotate_left,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: 'Open Crop Screen',
                child: IconButton(
                  onPressed: () => Get.to(CropPage(controller: _videoEditorController)),
                  icon: const Icon(
                    Icons.crop,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: 'Music',
                child: IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>
                        FindSong(audioFile: (file) async {
                          _audioFile = File(file);
                          await _player.setAudioSource(AudioSource.file(_audioFile!.path));
                          await _player.setLoopMode(LoopMode.one);
                          _player.setVolume(1.0);
                          _player.play();
                        }, isImageOrVideo: false,)));
                  },
                  icon: const Icon(
                    Icons.music_note,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: 'Rotate Clockwise',
                child: IconButton(
                  onPressed: () =>
                      _videoEditorController.rotate90Degrees(RotateDirection.right),
                  icon: const Icon(
                    Icons.rotate_right,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const VerticalDivider(endIndent: 16, indent: 16),
            Expanded(
              child: Tooltip(
                message: 'Open Export Menu',
                child: PopupMenuButton(
                  icon: const Icon(
                    Icons.save,
                    size: 30,
                    color: Colors.black,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => _exportCover(),
                      child: const Text('Export Cover'),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        setState(() {
                          _isLoading = true;
                        });
                        _exportAndMergeVideo();
                      },
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

  String formatter(Duration duration) => [
    duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
    duration.inSeconds.remainder(60).toString().padLeft(2, '0')
  ].join(":");

  List<Widget> trimmerViewForVideo() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _videoEditorController,
          _videoEditorController.video,
        ]),
        builder: (_, __) {
          final int duration = _videoEditorController.videoDuration.inSeconds;
          final double pos = _videoEditorController.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: _height / 4),
            child: Row(
              children: [
                Text(
                  formatter(Duration(seconds: pos.toInt())),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Expanded(child: SizedBox()),
                AnimatedOpacity(
                  opacity: _videoEditorController.isTrimming ? 1 : 0,
                  duration: kThemeAnimationDuration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter(_videoEditorController.startTrim),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatter(_videoEditorController.endTrim),
                        style: const TextStyle(color: Colors.black),
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
          controller: _videoEditorController,
          scrollController: ScrollController(keepScrollOffset: true),
          height: _height,
          horizontalMargin: _height / 4,
          child: TrimTimeline(
            controller: _videoEditorController,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      ),
    ];
  }

  void _exportCover() async {
    final config = CoverFFmpegVideoEditorConfig(_videoEditorController);
    final execute = await config.getExecuteConfig();
    if (execute == null) {
      if (mounted) showSnackBar(context: context,message: ("Error on cover exportation initialization."),isError: true);
      return;
    }

    await ExportService.runFFmpegCommand(
      execute,
      onError: (e, s) => showSnackBar(context: context, message: "Error on Export cover",isError: true),
      onCompleted: (cover) {
        if (!mounted) return;
        showDialog(context: context,builder: (_) => CoverResultPopup(cover: cover),);
      },
    );
  }

  Future<void> _exportAndMergeVideo() async {
    _isLoading = true;
    _isExporting.value = false;
    final config = VideoFFmpegVideoEditorConfig(_videoEditorController);

    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onError: (e, s) {
        _isLoading = false;
        if (mounted) { showSnackBar(context: context,message: "Error on Export video",isError: true); }
      },
      onCompleted: (exportedFile) async {
        if (mounted) {
          if (exportedFile.path.isNotEmpty && File(exportedFile.path).existsSync()) {
            _exportFilePath = exportedFile.path;

            _isLoading = true;
            if (_audioFile != null && _audioFile!.path.isNotEmpty) {
              try {
                _isExporting.value = false;

                final String videoPath = _exportFilePath;
                final String audioPath = _audioFile!.path;

                final mergedFilePath = await mergeAudioAndVideo(videoPath, audioPath);

                if (mergedFilePath.isNotEmpty) {
                  _isLoading = false;
                  _isExporting.value = true;

                  await ExportService.runFFmpegCommand(
                    await config.getExecuteConfig(),
                    onProgress: (stats) {
                      if (mounted) { _isLoading ? null : _exportingProgress.value = config.getFFmpegProgress(stats.getTime().round()); }
                    },
                    onError: (e, s) {
                      if (mounted) {
                        _isExporting.value = false;
                        _isLoading = false;
                        showSnackBar(context: context,message: "Error on Export merged video",isError: true);
                      }
                    },
                    onCompleted: (finalExportedFile) async {
                      if (mounted) {
                        _isExporting.value = false;
                        _isLoading = false;
                        _player.pause();
                        _player.dispose();

                        widget.navigateForIsStory ? widget.videoFileForEditingFunction(mergedFilePath) : Get.to(VideoResultPopup(video: File(mergedFilePath),isShowWidget: true,));
                        if (widget.navigateForIsStory) Navigator.pop(context);
                      }
                    },
                  );
                } else {
                  _isExporting.value = false;
                  _isLoading = false;
                  _exportingProgress.value = 0;
                  if (mounted) showSnackBar(context: context,message: "Error on Failed to merged video",isError: true);
                }
              } catch (e) {
                if (mounted) {
                  _isExporting.value = false;
                  _isLoading = false;
                  showSnackBar(context: context,message: "Error during merging: $e",isError: true);
                }
              }
            } else {
              _isExporting.value = false;
              _isLoading = false;
              widget.navigateForIsStory ? widget.videoFileForEditingFunction(_exportFilePath) : Get.to(VideoResultPopup(video: File(_exportFilePath),isShowWidget: true,));
              if (widget.navigateForIsStory) Navigator.pop(context);
            }
          } else {
            _isExporting.value = false;
            _isLoading = false;
            showSnackBar(context: context, message: "Failed to export video.",isError: true);
          }
        }
      },
    );
  }

  Future<String> mergeAudioAndVideo(String videoPath, String audioPath) async {
    try {
      final File audioFile = File(audioPath);

      final Directory? externalDir = await getExternalStorageDirectory();
      final String basePath = '${externalDir?.parent.parent.parent.parent.path}/Download/';

      String outputPath = "$basePath${DateTime.now().millisecondsSinceEpoch.toString()}.mp4";

      final File videoFile = File(videoPath);

      if (!await videoFile.exists()) {
        if (mounted) {
          showSnackBar(context: context,message: "Video file does not exist at: $videoPath",isError: true);
        }
      }
      if (!await audioFile.exists()) {
        if (mounted) {
          showSnackBar(context: context,message: "Audio file does not exist at: $audioPath",isError: true);
        }
      }

      final String command = "-y -i $videoPath -i $audioPath -map 0:v -map 1:a -c:v copy -shortest $outputPath";

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        await session.getAllLogs();

        if (ReturnCode.isSuccess(returnCode)) {
          return outputPath;
        } else if (ReturnCode.isCancel(returnCode)) {
          if (mounted) {
            showSnackBar(context: context,message: "FFmpeg command was canceled $returnCode",isError: true);
          }
        } else {
          if (mounted) {
            showSnackBar(context: context,message: "FFmpeg command failed: $returnCode",isError: true);
          }
        }
      });
      return outputPath;
    } catch (e) {
      if (mounted) {
        showSnackBar(context: context,message: "Error merging audio and video: $e",isError: true);
      }
      return e.toString();
    }
  }

  Widget _coverSelection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _videoEditorController,
            size: _height + 10,
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
