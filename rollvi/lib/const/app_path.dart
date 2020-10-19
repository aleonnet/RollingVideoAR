import 'dart:io';

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';

FlutterFFmpeg ffmpeg = FlutterFFmpeg();

Future<String> getRollviTempDir() async {
  final rawDir = (await getTemporaryDirectory()).path;
  return '$rawDir/rollvi';
}

void clearRollviTempDir() async {
  final rollviDir = await getRollviTempDir();
  Directory(rollviDir).delete(recursive: true);
}

void createRollviTempDir() async {
  final rollviDir = await getRollviTempDir();
  Directory(rollviDir).createSync(recursive: true);
}