import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:videoapp/ui/view/video_edit/audio_trimmer.dart';
import 'package:videoapp/ui/view/video_edit/wave.dart';
import '../../../core/model/song_model.dart';

class FindSong extends StatefulWidget {
  final Duration duration;
  final File file;
  const FindSong({super.key, required this.duration, required this.file});

  @override
  State<FindSong> createState() => _FindSongState();
}

class _FindSongState extends State<FindSong> {
  ValueNotifier<int> isSelectedPlayIndex = ValueNotifier(-1);
  final AudioPlayer player = AudioPlayer();
  final TextEditingController searchController = TextEditingController();

  List<Song> allSongs = [];
  List<Song> filteredSongs = [];

  @override
  void initState() {
    super.initState();
    fetchSongs().then((songs) {
      setState(() {
        allSongs = songs;
        filteredSongs = songs;
      });
    });

    searchController.addListener(_filterSongs);
  }

  Future<List<Song>> fetchSongs() async {
    final String response = await rootBundle.loadString('assets/json/music.json');
    final List<dynamic> jsonList = jsonDecode(response);
    return jsonList.map((json) => Song.fromJson(json)).toList();
  }

  void _filterSongs() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredSongs = allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    player.dispose();
    searchController.removeListener(_filterSongs);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: SizedBox(
          height: 40,
          child: TextFormField(
            controller: searchController,
            textAlign: TextAlign.start,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: "Search",
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            autofillHints: const [AutofillHints.name],
          ),
        ),
      ),
      body: SafeArea(
        child: filteredSongs.isNotEmpty ?
        ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredSongs.length,
          itemBuilder: (context, index) {
            final song = filteredSongs[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () async {
                  /*String videoPath = widget.file.path;
                  String audioUrl = song.url;

                  print("Audio $audioUrl");
                  print("Audio $audioUrl");
                    mergeAudioAndVideo(videoPath, audioUrl).then((outputPath) {
                      print('Merged video saved at $outputPath');
                    }).catchError((error) {
                      print('Error: $error');
                    });
                    */

                  String audioUrl = song.url;
                  downloadAndTrimAudio(audioUrl, song, context);

                  //Navigator.pop(context);
               /*   Map<String, dynamic> map = {
                    "id": song.id,
                    "title": song.title,
                    "artist": song.artist,
                    "artwork": song.artwork,
                    "url": song.url,
                  };
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AudioTrimmerViewDemo(file: widget.file, song: map,)));*/
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withOpacity(0.2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
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
        )
            : const Center(child: Text('No songs found')),
      ),
    );
  }

  ///   Merge Audio and Video [mergeAudioAndVideo] and [getUniqueFilePath]
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
      final String basePath =
          '${externalDir?.parent.parent.parent.parent.path}/Download/';

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

      final String command =
          "-y -i $videoPath -i $audioPath -map 0:v -map 1:a -c:v copy -shortest $outputPath";

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

  /// Trim and Navigate [downloadAndTrimAudio]
  Future<void> downloadAndTrimAudio(String url, Song map, BuildContext context) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String audioPath = '${appDir.path}/_audio.mp3';

      print("App directory: ${appDir.path}");

      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final File audioFile = File(audioPath);
        audioFile.writeAsBytes(response.bodyBytes).then((_) {
          print("Audio File saved at: $audioPath");
          Get.off(WaveAudio(file: audioFile, song: map,duration: widget.duration));
        }).catchError((error) {
          print("File write error: ${error.toString()}");
        });

      } else {
        print(
            "Failed to download audio: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to download audio');
      }
    } catch (e) {
      print("Error: ${e.toString()}");
    }
  }
}
