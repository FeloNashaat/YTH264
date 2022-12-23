import 'dart:io';
import 'dart:isolate';

import 'package:YT_H264/Services/QueueObject.dart';

class DownloadObject {
  //For Debugging
  int id;

  SendPort port;
  SendPort? streamPort;
  YoutubeQueueObject ytData;
  Directory tmp;
  Directory downloads;
  DownloadObject(
      {required this.id,
      required this.port,
      required this.ytData,
      required this.tmp,
      required this.downloads});
}
