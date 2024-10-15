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
