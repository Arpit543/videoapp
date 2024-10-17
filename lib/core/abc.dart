// import 'dart:io';
// import 'package:ffmpeg_kit_flutter_min/return_code.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
//
// Future<String> addMusicToImage(String imagePath, String audioUrl, {int durationInSeconds = 10}) async {
//   try {
//     final Directory appDir = await getApplicationDocumentsDirectory();
//     final String audioPath = '${appDir.path}/temp_audio.mp3';
//
//     final http.Response response = await http.get(Uri.parse(audioUrl));
//     if (response.statusCode == 200) {
//       final File audioFile = File(audioPath);
//       await audioFile.writeAsBytes(response.bodyBytes);
//       print("Audio downloaded and saved at: $audioPath");
//     } else {
//       throw Exception('Failed to download audio: ${response.statusCode} ${response.reasonPhrase}');
//     }
//
//     final Directory? externalDir = await getExternalStorageDirectory();
//     final String basePath = '${externalDir?.parent.parent.parent.parent.path}/Download/';
//     String outputPath = getUniqueFilePath(basePath, "output_image_video", "mp4");
//
//     final File imageFile = File(imagePath);
//     if (!await imageFile.exists()) {
//       throw Exception('Image file does not exist at: $imagePath');
//
//
//     print("Image Path: $imagePath");
//     print("Audio Path: $audioPath");
//     print("Output Video Path: $outputPath");
//
//
//     final String ffmpegCommand =
//         '-loop 1 -i "$imagePath" -i "$audioPath" -c:v libx264 -c:a aac -b:a 192k -shortest -t $durationInSeconds "$outputPath"';
//
//     await FFmpegKit.execute(ffmpegCommand).then((session) async {
//       final returnCode = await session.getReturnCode();
//       final log = await session.getAllLogs();
//       log.forEach((log) {
//         print(log.getMessage());
//       });
//
//       if (ReturnCode.isSuccess(returnCode)) {
//         print("Output Video Path: $outputPath");
//         return outputPath;
//       } else if (ReturnCode.isCancel(returnCode)) {
//         throw Exception('FFmpeg command was canceled');
//       } else {
//         throw Exception('FFmpeg command failed with return code: $returnCode');
//       }
//     });
//
//     return outputPath;
//   } catch (e) {
//     throw Exception('Error adding music to image: $e');
//   }
// }
//
//
// String getUniqueFilePath(String basePath, String fileName, String extension) {
//   int count = 0;
//   String fullPath = '$basePath$fileName.$extension';
//
//   while (File(fullPath).existsSync()) {
//     count++;
//     fullPath = '$basePath$fileName$count.$extension';
//   }
//
//   return fullPath;
// }
/*
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
                  Map<String, dynamic> map = {
                    "title": song.title,
                    "artist": song.artist,
                    "artwork": song.artwork,
                    "url": song.url,
                    "id": song.id
                  };
                  print(" Map:- $map");
                  *//*print("Audio $audioUrl");
                    mergeAudioAndVideo(videoPath, audioUrl).then((outputPath) {
                      print('Merged video saved at $outputPath');
                    }).catchError((error) {
                      print('Error: $error');
                    });*//*
                  Navigator.push(context,MaterialPageRoute(builder: (context) => AudioTrimmerViewDemo(song: map,),));
                  // downloadAndTrimAudio(audioUrl, context);
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
                                  Future.delayed(
                                      const Duration(milliseconds: 300),
                                          () async => await player.pause());
                                } else {
                                  isSelectedPlayIndex.value = index;
                                  await player.setAudioSource(
                                      AudioSource.uri(Uri.parse(song.url)));
                                  await player.play();
                                }
                              },
                              icon: indexValue == index
                                  ? const Icon(Icons.pause)
                                  : const Icon(Icons.play_arrow),
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
}*/
