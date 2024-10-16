import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/model/song_model.dart';
import 'audio_trimmer.dart';

class FindSong extends StatefulWidget {
  const FindSong({super.key});

  @override
  State<FindSong> createState() => _FindSongState();
}

class _FindSongState extends State<FindSong> {
  ValueNotifier<int> isSelectedPlayIndex = ValueNotifier(-1);
  final AudioPlayer player = AudioPlayer();

  ///   To get Song from URL [fetchSongs]
  Future<List<Song>> fetchSongs() async {
    final String response =
    await rootBundle.loadString('assets/json/music.json');
    final List<dynamic> jsonList = jsonDecode(response);
    return jsonList.map((json) => Song.fromJson(json)).toList();
  }

  @override
  void initState() {
    fetchSongs();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: SizedBox(
          height: 40,
          child: TextFormField(
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
            validator: (value) {
              return null;
            },
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, color: Colors.black),
          )
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Song>>(
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
                      Map<String, dynamic> map = {
                        "id": song.id,
                        "title": song.title,
                        "artist": song.artist,
                        "artwork": song.artwork,
                        "url": song.url,
                      };
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AudioTrimmerViewDemo(song: map,),));
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
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const CircularProgressIndicator();
        },
      ),
      ),
    );
  }
}
