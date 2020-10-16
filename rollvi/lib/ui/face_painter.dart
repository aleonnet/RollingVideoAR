import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:rollvi/darwin_camera/darwin_camera.dart';


class FaceContourPainter extends CustomPainter {
  final List<Rect> rects = [];

  final Size imageSize;
  final List<Face> faces;
  final CameraLensDirection cameraLensDirection;

  FaceContourPainter(this.imageSize, this.faces, this.cameraLensDirection) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..color = Colors.yellow;

    for (var i = 0; i < faces.length; i++) {
//      canvas.drawRect(rects[i], paint);

      final List<Offset> facePoints =
          faces[i]
              .getContour(FaceContourType.face)
              .positionsList;
      final List<Offset> lowerLipBottom =
          faces[i]
              .getContour(FaceContourType.lowerLipBottom)
              .positionsList;
      final List<Offset> lowerLipTop =
          faces[i]
              .getContour(FaceContourType.lowerLipTop)
              .positionsList;
      final List<Offset> upperLipBottom =
          faces[i]
              .getContour(FaceContourType.upperLipBottom)
              .positionsList;
      final List<Offset> upperLipTop =
          faces[i]
              .getContour(FaceContourType.upperLipTop)
              .positionsList;
      final List<Offset> leftEyebrowBottom =
          faces[i]
              .getContour(FaceContourType.leftEyebrowBottom)
              .positionsList;
      final List<Offset> leftEyebrowTop =
          faces[i]
              .getContour(FaceContourType.leftEyebrowTop)
              .positionsList;
      final List<Offset> rightEyebrowBottom =
          faces[i]
              .getContour(FaceContourType.rightEyebrowBottom)
              .positionsList;
      final List<Offset> rightEyebrowTop =
          faces[i]
              .getContour(FaceContourType.rightEyebrowTop)
              .positionsList;
      final List<Offset> leftEye =
          faces[i]
              .getContour(FaceContourType.leftEye)
              .positionsList;
      final List<Offset> rightEye =
          faces[i]
              .getContour(FaceContourType.rightEye)
              .positionsList;
      final List<Offset> noseBottom =
          faces[i]
              .getContour(FaceContourType.noseBottom)
              .positionsList;
      final List<Offset> noseBridge =
          faces[i]
              .getContour(FaceContourType.noseBridge)
              .positionsList;

      final lipPaint = Paint()
        ..strokeWidth = 3.0
        ..color = Colors.pink;

      canvas.drawCircle(
          _scalePoint(
            offset:(upperLipBottom[4] + lowerLipTop[4]) / 2,
            imageSize: imageSize,
            widgetSize: size
          ),
          3.0, lipPaint);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: lowerLipBottom, imageSize: imageSize, widgetSize: size),
          lipPaint);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: lowerLipTop, imageSize: imageSize, widgetSize: size),
          lipPaint);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: upperLipBottom, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.green);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: upperLipTop, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.green);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: leftEyebrowBottom,
              imageSize: imageSize,
              widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.brown);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: leftEyebrowTop, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.brown);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: rightEyebrowBottom,
              imageSize: imageSize,
              widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.brown);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: rightEyebrowTop, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.brown);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: leftEye, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.blue);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: rightEye, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.blue);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: noseBottom, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.greenAccent);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: noseBridge, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.greenAccent);

      canvas.drawPoints(
          ui.PointMode.polygon,
          _scalePoints(
              offsets: facePoints, imageSize: imageSize, widgetSize: size),
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.white);
    }
  }

  List<Offset> _scalePoints({
    List<Offset> offsets,
    @required Size imageSize,
    @required Size widgetSize,
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
  }) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    if (cameraLensDirection == CameraLensDirection.front) {
      return Offset(widgetSize.width - (offset.dx * scaleX), offset.dy * scaleY);
    }
    return Offset(offset.dx * scaleX, offset.dy * scaleY);
  }

  @override
  bool shouldRepaint(FaceContourPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize || faces != oldDelegate.faces;
  }
}
