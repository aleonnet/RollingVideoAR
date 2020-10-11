import 'dart:io';

import 'package:path_provider/path_provider.dart';

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