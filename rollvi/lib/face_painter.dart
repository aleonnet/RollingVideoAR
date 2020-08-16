import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';


class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      print(faces[i]);
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..color = Colors.yellow;

    final Size imageSize = Size(
        image.width.toDouble(), image.height.toDouble());

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);

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

      print(faces[i]
          .getContour(FaceContourType.face)
          .positionsList);

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

    return offsets
        .map((offset) => Offset(offset.dx * scaleX, offset.dy * scaleY))
        .toList();
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
