import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'backup/face_painter.dart';

enum FilterLocation {
  Mouse,
  LeftEar,
}

class ARFilter {
  List<String> assetNames = List<String>();
  FilterLocation location = FilterLocation.Mouse;

  double width = 0.0;
  double height = 0.0;
}

class FaceCamera extends StatelessWidget {
  final List<Face> faces;
  final CameraController camera;
  final bool showFaceContour;
  final int filterIndex;

  const FaceCamera(
      {Key key, this.faces, this.camera, this.showFaceContour = false, this.filterIndex = 1})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        CameraPreview(camera),
        showFaceContour ? _getFaceContourPaint(faces, camera) : Container(),
//        _getLeftEarStickerWidget(faces, camera, filterIndex),
        _getMouseStickerWidget(faces, camera, filterIndex),
      ],
    );
  }

  Widget _getMouseStickerWidget(List<Face> faces, CameraController camera, int filterIndex) {
    if (faces == null) {
      return new Text("");
    }

    Size imageSize = Size(
      camera.value.previewSize.height,
      camera.value.previewSize.width,
    );

    final ARFilter arFilter = _getMouseARFilter(filterIndex);
    final Offset lipBottomPoint = _getLipBottomPoint(faces, imageSize);

    final double left = (filterIndex == 5) ? 0 : lipBottomPoint.dx;
    final double top = (filterIndex == 5) ? 20 : lipBottomPoint.dy - (arFilter.height * 1/2) - 20;

    Widget stickerWidgets = new Positioned(
        left: left,
        top: top,
        child: new Stack(
          children: <Widget>[
            for (var assetName in arFilter.assetNames)
              _getStickerWidget(assetName, arFilter.width, arFilter.height),
          ],
        ));

    return stickerWidgets;
  }

  Widget _getLeftEarStickerWidget(List<Face> faces, CameraController camera, int filterIndex) {
    final double width = 200;
    final double height = 300;

    if (faces == null) {
      return new Text("");
    }

    Size imageSize = Size(
      camera.value.previewSize.height,
      camera.value.previewSize.width,
    );

    final ARFilter arFilter = _getLeftEarARFilter(filterIndex);
    final Offset leftEarPoint = _getLeftEarPoint(faces, imageSize);

    Widget stickerWidgets = new Positioned(
        width: width,
        height: height,
        right: leftEarPoint.dx * -1 + 415,
        top: leftEarPoint.dy - 60,
        child: new Stack(
          children: <Widget>[
            for (var assetName in arFilter.assetNames)
              _getStickerWidget(assetName, arFilter.width, arFilter.height),
          ],
        ));

    return stickerWidgets;
  }

  ARFilter _getMouseARFilter(int filterIndex) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.Mouse;

    switch(filterIndex) {
      case 1:
        arFilter.assetNames.add("assets/say_m01.webp");
        arFilter.width = 200;
        arFilter.height = 100;
        break;
      case 2:
        arFilter.assetNames.add("assets/say_m02.webp");
        arFilter.width = 300;
        arFilter.height = 250;
        break;
      case 3:
        arFilter.assetNames.add("assets/say_m03.webp");
        arFilter.width = 450;
        arFilter.height = 400;
        break;
      case 4:
        arFilter.assetNames.add("assets/say_m04.webp");
        arFilter.width = 450;
        arFilter.height = 400;
        break;
      case 5:
        arFilter.assetNames.add("assets/say_m05.webp");
        arFilter.width = 450;
        arFilter.height = 600;
        break;
      case 0:
      default:
        break;
    }

    return arFilter;
  }

  ARFilter _getLeftEarARFilter(int filterIndex) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.LeftEar;
    arFilter.height = 300;

    switch(filterIndex) {
      case 1:
        arFilter.assetNames.add("assets/hear_text.gif");
        arFilter.assetNames.add("assets/hear_heart.gif");
        arFilter.width = 200;
        break;
      case 2:
        arFilter.assetNames.add("assets/hear_text.gif");
        arFilter.assetNames.add("assets/hear_heart.gif");
        arFilter.width = 250;
        break;
      case 3:
        arFilter.assetNames.add("assets/hear_text.gif");
        arFilter.assetNames.add("assets/hear_heart.gif");
        arFilter.width = 300;
        break;
      case 4:
        arFilter.assetNames.add("assets/hear_text.gif");
        arFilter.assetNames.add("assets/hear_heart.gif");
        arFilter.width = 350;
        break;
      case 5:
        arFilter.assetNames.add("assets/hear_text.gif");
        arFilter.assetNames.add("assets/hear_heart.gif");
        arFilter.width = 400;
        break;
      case 0:
      default:
        break;
    }

    return arFilter;
  }

  Widget _getStickerWidget(String assetName, double width, double height) {

    Widget stickerWidget = Positioned(
      child: new Container(
//        color: Colors.blue,
          child: new Image(
            fit: BoxFit.contain,
        image: new AssetImage(assetName),
        width: width,
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
