import 'dart:io';
import 'dart:typed_data';
import 'package:darwin_camera/darwin_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';


Future<File> writeLog(String message) async {
  final now = DateTime.now().toLocal();
  final String curDate = DateFormat('MM-dd').format(now);
  final String curTime = DateFormat('MM-dd hh:mm:ss').format(now);

//  final directory = await getApplicationDocumentsDirectory();
  final directory = await getExternalStorageDirectory();
  final path = await directory.path;

  File file = File('$path/log_$curDate.txt');
  file.writeAsString('[$curTime] $message\n', mode: FileMode.append);

  print(message);
}

List<Offset> _scalePoints({
  List<Offset> offsets,
  @required Size imageSize,
  @required Size widgetSize,
  CameraLensDirection cameraLensDirection
}) {
  final double scaleX = widgetSize.width / imageSize.width;
  final double scaleY = widgetSize.height / imageSize.height;

  if (cameraLensDirection == CameraLensDirection.front) {
    return offsets
        .map((offset) => Offset(
        widgetSize.width - (offset.dx * scaleX), offset.dy * scaleY))
        .toList();
  }
  return offsets
      .map((offset) => Offset(offset.dx * scaleX, offset.dy * scaleY))
      .toList();
}

Offset _scalePoint({
  Offset offset,
  @required Size imageSize,
  @required Size widgetSize,
  CameraLensDirection cameraLensDirection
}) {
  final double scaleX = widgetSize.width / imageSize.width;
  final double scaleY = widgetSize.height / imageSize.height;

  if (cameraLensDirection == CameraLensDirection.front) {
    return Offset(widgetSize.width - (offset.dx * scaleX), offset.dy * scaleY);
  }
  return Offset(offset.dx * scaleX, offset.dy * scaleY);
}

ImageRotation rotationIntToImageRotation(int rotation) {
  switch (rotation) {
    case 0:
      return ImageRotation.rotation0;
    case 90:
      return ImageRotation.rotation90;
    case 180:
      return ImageRotation.rotation180;
    default:
      assert(rotation == 270);
      return ImageRotation.rotation270;
  }
}

Uint8List concatenatePlanes(List<Plane> planes) {
  final WriteBuffer allBytes = WriteBuffer();
  planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
  return allBytes.done().buffer.asUint8List();
}

FirebaseVisionImageMetadata buildMetaData(
    CameraImage image,
    ImageRotation rotation,
    ) {
  return FirebaseVisionImageMetadata(
    rawFormat: image.format.raw,
    size: Size(image.width.toDouble(), image.height.toDouble()),
    rotation: rotation,
    planeData: image.planes.map(
          (Plane plane) {
        return FirebaseVisionImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList(),
  );
}
