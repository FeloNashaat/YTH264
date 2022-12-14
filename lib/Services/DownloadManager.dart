import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:YT_H264/Services/DownloadObject.dart';
import 'package:YT_H264/Services/GlobalMethods.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:remove_emoji/remove_emoji.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../Widgets/QueueWidget.dart';
import 'QueueObject.dart';

class DownloadManager {
  static StreamController<DownloadObject> downloadStreamController =
      StreamController<DownloadObject>();
  static Stream downloadStream = downloadStreamController.stream;
  static bool isDownloading = false;

  //// void registerInQueue(Map<String, dynamic> downloadData) {
  ////   if (downloadQueue.isEmpty) {
  ////     downloadQueue.add(downloadData);
  //     // donwloadVideoFromYoutube(args)
  ////   }
  ////   downloadQueue.add(downloadData);
  //// }

  @pragma('vm:entry-point')
  static void donwloadVideoFromYoutube(DownloadObject args) async {
    final SendPort sd = args.port;
    ReceivePort rc = ReceivePort();
    sd.send([rc.sendPort]);
    rc.listen(((message) {
      args.streamPort!.send([]);
      Isolate.exit();
    }));

    print('Starting Download');
    final yt = YoutubeExplode();
    double progress = 0;
    String? vidDir, audioDir;
    String title = args.ytData.title;
    title = title
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '')
        .replaceAll(':', '')
        .replaceAll("'", '')
        .replaceAll('"', '');
    title = RemoveEmoji().removemoji(title);

    if (args.ytData.downloadType == DownloadType.VideoOnly ||
        args.ytData.downloadType == DownloadType.Muxed) {
      try {
        var stream =
            yt.videos.streamsClient.get(args.ytData.stream as StreamInfo);
        final size = args.ytData.stream!.size.totalBytes;
        var count = 0;
        String? fileDir;
        Directory? directory;
        if (args.ytData.downloadType == DownloadType.VideoOnly) {
          directory = args.downloads;
        } else {
          directory = args.tmp;
        }
        fileDir =
            '${directory.path}/$title.${args.ytData.stream!.container.name}';
        vidDir = fileDir;
        if (await File(fileDir).exists()) {
          await File(fileDir).delete();
        }
        File vidFile = await File(fileDir).create(recursive: true);
        var fileStream = vidFile.openWrite(mode: FileMode.writeOnlyAppend);
        await for (var bytes in stream) {
          fileStream.add(bytes);
          count += bytes.length;
          var currentProgress = ((count / size) * 100);
          progress = currentProgress;
          if (args.ytData.downloadType == DownloadType.Muxed) {
            currentProgress = progress / 2;
          }
          print(currentProgress);
          sd.send([DownloadStatus.downloading, currentProgress]);
        }
      } catch (e) {
        sd.send([e.toString()]);
        args.streamPort!.send([]);
        Isolate.exit();
      }
    }

    if (args.ytData.downloadType == DownloadType.AudioOnly ||
        args.ytData.downloadType == DownloadType.Muxed) {
      try {
        final audioStream = yt.videos.streamsClient.get(args.ytData.bestAudio);
        final size = args.ytData.bestAudio.size.totalBytes;
        var count = 0;
        String? fileDir;
        Directory? directory;
        if (args.ytData.downloadType == DownloadType.AudioOnly) {
          directory = args.downloads;
        } else {
          directory = args.tmp;
        }

        fileDir =
            '${directory.path}/$title.${args.ytData.bestAudio.container.name}';
        audioDir = fileDir;
        if (await File(fileDir).exists()) {
          await File(fileDir).delete();
        }
        File audFile = await File(fileDir).create(recursive: true);
        var fileStream =
            await audFile.openWrite(mode: FileMode.writeOnlyAppend);
        await for (var bytes in audioStream) {
          fileStream.add(bytes);
          count += bytes.length;
          double currentProgress = ((count / size) * 100);
          progress = 100 + currentProgress;
          if (args.ytData.downloadType == DownloadType.Muxed) {
            currentProgress = progress / 2;
          }
          print(currentProgress);
          sd.send([DownloadStatus.downloading, currentProgress]);
        }
      } catch (e) {
        sd.send([e.toString()]);
        args.streamPort!.send([]);
        Isolate.exit();
      }
    }

    yt.close();

    if (args.ytData.downloadType == DownloadType.VideoOnly) {
      sd.send([DownloadStatus.done, 100.0]);
    } else {
      sd.send([DownloadStatus.converting, 100.0]);
    }
    args.streamPort!.send([]);
    Isolate.exit();
  }

  static void convertToMp3(
      Directory? downloads,
      String title,
      YoutubeQueueObject ytobj,
      Function callBack,
      Directory temp,
      BuildContext context) async {
    title = RemoveEmoji().removemoji(title);
    title = title
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '')
        .replaceAll(':', '')
        .replaceAll("'", '')
        .replaceAll('"', '');
    String imgPath = '${temp.path}/${title}.jpg';
    File? imgfile = await getImageAsFile(ytobj.thumbnail, imgPath);
    String audioDir =
        '"${downloads!.path}/$title.${ytobj.bestAudio.container.name}"';
    String command = '';

    if (imgfile != null) {
      command =
          '-y -i $audioDir -i "$imgPath" -map 0 -map 1 -metadata artist="${ytobj.author}" -metadata title="${ytobj.title}" "${downloads.path}/$title.mp3"';
    } else {
      command = '-y -i $audioDir "${downloads.path}/$title.mp3"';
    }

    print(command);
    FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode) &&
          !ReturnCode.isCancel(returnCode)) {
        GlobalMethods.snackBarError(session.getOutput().toString(), context);
      }
      File old = File(audioDir.replaceAll('"', ''));
      try {
        await old.delete();
      } catch (e) {}
      if (imgfile != null) {
        await imgfile.delete();
      }
      // print(session.)
      callBack();
      return;
    }, ((log) {
      print(log.getMessage());
    }));
  }

  static void mergeIntoMp4(Directory? temps, Directory? downloads, String title,
      Function callBack, BuildContext context) {
    title = RemoveEmoji().removemoji(title);
    title = title
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '')
        .replaceAll(':', '')
        .replaceAll("'", '')
        .replaceAll('"', '');
    String audioDir = "'${temps!.path}/$title.webm'";
    String videoDir = "'${temps.path}/$title.mp4'";
    String outDir = "'${downloads!.path}/$title.mp4'";
    FFmpegKit.executeAsync(
        '-y -i $videoDir -i $audioDir -c:v copy -c:a aac $outDir',
        (session) async {
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode) &&
          !ReturnCode.isCancel(returnCode)) {
        String? msg = await session.getOutput();
        GlobalMethods.snackBarError(msg!, context);
      }
      print(session.getOutput());
      File oldAudio = File(audioDir.replaceAll("'", ''));
      await oldAudio.delete();
      File oldVideo = File(videoDir.replaceAll("'", ''));
      await oldVideo.delete();
      callBack();
    }, ((log) {
      print(log.getMessage());
    }));
  }

  static Future<File?> getImageAsFile(String uri, String path) async {
    final file = File(path);
    try {
      final response = await http.get(Uri.parse(uri));

      file.writeAsBytesSync(response.bodyBytes);

      return file;
    } catch (e) {
      return null;
    }
  }

  static void stop(DownloadStatus ds, YoutubeQueueObject queueObject,
      Directory downloads, Directory temps, SendPort? stopper) async {
    if (stopper == null) {
      return;
    }
    String fixedTitle = queueObject.title
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '')
        .replaceAll(':', '')
        .replaceAll("'", '')
        .replaceAll('"', '');
    if (ds == DownloadStatus.downloading) {
      stopper.send(null);
    } else {
      FFmpegKit.cancel();
    }
    if (queueObject.downloadType == DownloadType.AudioOnly) {
      String path = '${downloads.path}/$fixedTitle.webm';
      File file = File(path);

      String outpath = '${downloads.path}/$fixedTitle.mp3';
      File outfile = File(outpath);

      try {
        await file.delete();
        await outfile.delete();
      } catch (e) {}
    } else if (queueObject.downloadType == DownloadType.VideoOnly) {
      String path = '${downloads.path}/$fixedTitle.mp4';
      File file = File(path);

      try {
        await file.delete();
      } catch (e) {}
    } else {
      String pathToVid = '${temps.path}/$fixedTitle.mp4';
      File vidfile = File(pathToVid);

      String pathToAud = '${temps.path}/$fixedTitle.webm';
      File audfile = File(pathToAud);

      String pathToOut = '${downloads.path}/$fixedTitle.mp4';
      File outfile = File(pathToOut);

      try {
        await vidfile.delete();
        await audfile.delete();
        await outfile.delete();
      } catch (e) {}
    }
  }
}
