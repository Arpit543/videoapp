import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:video_editor/video_editor.dart';

class ExportService {
  static Future<void> dispose() async {
    final executions = await FFmpegKit.listSessions();
    if (executions.isNotEmpty) {
      log('Cancelling ongoing FFmpeg sessions.');
      await FFmpegKit.cancel();
    } else {
      log('No FFmpeg sessions to cancel.');
    }
  }

  static Future<FFmpegSession> runFFmpegCommand(
      FFmpegVideoEditorExecute execute, {
        required void Function(File file) onCompleted,
        void Function(Object, StackTrace)? onError,
        void Function(Statistics)? onProgress,
      }) {
    log('FFmpeg start process with command = ${execute.command}');
    return FFmpegKit.executeAsync(
      execute.command,
          (session) async {
        final state = FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();
        final output = await session.getOutput();

        if (ReturnCode.isSuccess(code)) {
          log('FFmpeg process completed successfully.');
          onCompleted(File(execute.outputPath));
        } else {
          log('FFmpeg process failed with state: $state and return code: $code.\nOutput: $output');
          if (onError != null) {
            onError(Exception('FFmpeg process exited with state $state and return code $code.\nOutput: $output'), StackTrace.current);
          }
        }
      },
      null,
      onProgress,
    );
  }
}
