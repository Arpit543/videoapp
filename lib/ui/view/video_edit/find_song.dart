import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:videoapp/ui/view/video_edit/audio_trimmer.dart';
import '../../../core/model/song_model.dart';

class FindSong extends StatefulWidget {
  final Function(String file) audioFile;
  const FindSong({super.key, required this.audioFile});

  @override
  State<FindSong> createState() => _FindSongState();
}

class _FindSongState extends State<FindSong> {
  ValueNotifier<int> isSelectedPlayIndex = ValueNotifier(-1);
  final AudioPlayer player = AudioPlayer();
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;
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
      body: Stack(
        children: [
          SafeArea(
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
                      setState(() {
                        isLoading = true;
                      });

                      String audioUrl = song.url;
                      await downloadAndTrimAudio(audioUrl, song, context);

                      setState(() {
                        isLoading = false;
                      });

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
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

        ],
      ),
    );
  }

  /// Trim and Navigate [downloadAndTrimAudio]
  Future<void> downloadAndTrimAudio(String url, Song map, BuildContext context) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String audioPath = '${appDir.path}/_audio.mp3';

      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final File audioFile = File(audioPath);
        await audioFile.writeAsBytes(response.bodyBytes).then((_) async {
          // Get.off(AudioTrimmerViewDemo(videoFile: audioFile, song: map, videoDuration: widget.videoDuration));
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => AudioTrimmerViewDemo(videoFile: audioFile, song: map, audioFile: (file) {
                print("come back 123 $file");
                widget.audioFile(file);
              })));

        }).catchError((error) {

        });

      } else {
        throw Exception('Failed to download audio');
      }
    } catch (e) {
      Text(e.toString());
    }
  }
}
