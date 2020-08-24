import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'backup/face_painter.dart';

class FaceCamera extends StatelessWidget {
  final List<Face> faces;
  final CameraController camera;
  final bool cameraEnabled;

  const FaceCamera(
      {Key key, this.faces, this.camera, this.cameraEnabled = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        cameraEnabled ? CameraPreview(camera) : Container(color: Colors.black),
//            _getFaceContourPaint(faces, camera),
        _getLeftEarStickerWidget(faces, camera),
        _getMouseStickerWidget(faces, camera),
      ],
    );
  }

  Widget _getMouseStickerWidget(List<Face> faces, CameraController camera) {
    final double width = 200;
    final double height = 300;

    if (faces == null) {
      return new Text("");
    }

    Size imageSize = Size(
      camera.value.previewSize.height,
      camera.value.previewSize.width,
    );

    Offset lipBottomPoint = _getLipBottomPoint(faces, imageSize);

    Widget stickerWidgets = new Positioned(
        width: width,
        height: height,
        left: lipBottomPoint.dx,
        top: lipBottomPoint.dy - 100,
        child: new Stack(
          children: <Widget>[
            _getStickerWidget("assets/say_t01.webp"),
            _getStickerWidget("assets/say_h01.webp"),
          ],
        ));

    return stickerWidgets;
  }

  Widget _getLeftEarStickerWidget(List<Face> faces, CameraController camera) {
    final double width = 200;
    final double height = 300;

    if (faces == null) {
      return new Text("");
    }

    Size imageSize = Size(
      camera.value.previewSize.height,
      camera.value.previewSize.width,
    );

    Offset leftEarPoint = _getLeftEarPoint(faces, imageSize);

    Widget stickerWidgets = new Positioned(
        width: width,
        height: height,
        right: leftEarPoint.dx * -1 + 420,
        top: leftEarPoint.dy - 100,
        child: new Stack(
          children: <Widget>[
            _getStickerWidget("assets/hear_text.gif"),
            _getStickerWidget("assets/hear_heart.gif"),
          ],
        ));

    return stickerWidgets;
  }

  Widget _getStickerWidget(String assetName) {
    final double height = 300;

    Widget stickerWidget = Positioned(
      child: new Container(
          child: new Image(
        image: new AssetImage(assetName),
        height: height,
        alignment: Alignment.center,
      )),
    );

    return stickerWidget;
  }

  Widget _getFaceContourPaint(List<Face> faces, CameraController camera) {
    if (faces == null || camera == null) return Text("");

    return new CustomPaint(
      painter: FaceContourPainter(
          Size(
            camera.value.previewSize.height,
            camera.value.previewSize.width,
          ),
          faces,
          camera.description.lensDirection),
    );
  }

  Offset _getLeftEarPoint(List<Face> faces, Size imageSize) {
    final defaultOffset = Offset(-500, -500);

    if (faces == null) return defaultOffset;

    try {
      Face face = faces[0];

      return _scalePoint(
          offset: face.getContour(FaceContourType.face).positionsList[9],
          imageSize: imageSize,
          widgetSize: Size(411.4, 685.7),
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return defaultOffset;
    }
  }

  Offset _getLipBottomPoint(List<Face> faces, Size imageSize) {
    final Offset defaultOffset = Offset(-500, -500);
    final double mouseOpenThreshold = 15;

    if (faces == null) return defaultOffset;

    try {
      Face face = faces[0];

      Offset upperLipBottom =
          face.getContour(FaceContourType.upperLipBottom).positionsList[4];
      Offset lowerLipTop =
          face.getContour(FaceContourType.lowerLipTop).positionsList[4];

      double offsetMouse = lowerLipTop.dy - upperLipBottom.dy;

      if (offsetMouse > mouseOpenThreshold) {
        print("Open Mouse");
        return _scalePoint(
            offset: (upperLipBottom + lowerLipTop) / 2.0,
            imageSize: imageSize,
            widgetSize: Size(411.4, 685.7),
            cameraLensDirection: CameraLensDirection.front);
      }
    } catch (e) {
      return defaultOffset;
    }

    return defaultOffset;
  }

  Offset _scalePoint(
      {Offset offset,
      @required Size imageSize,
      @required Size widgetSize,
      CameraLensDirection cameraLensDirection}) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    if (cameraLensDirection == CameraLensDirection.front) {
      return Offset(
          widgetSize.width - (offset.dx * scaleX), offset.dy * scaleY);
    }
    return Offset(offset.dx * scaleX, offset.dy * scaleY);
  }
}
