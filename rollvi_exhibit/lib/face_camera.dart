import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:darwin_camera/darwin_camera.dart';
import 'package:rollvi_exhibit/face_painter.dart';
import 'dart:math' as math;

import 'package:rollvi_exhibit/utils.dart';

enum FilterLocation {
  Mouse,
  LeftEar,
}

class ARFilter {
  List<String> assetNames = List<String>();
  FilterLocation location = FilterLocation.Mouse;

  double width = 0.0;
  double height = 0.0;

  Offset offset = new Offset(0.0, 0.0);
}

class FaceCamera extends StatefulWidget {
  final List<Face> faces;
  final CameraController camera;
  final bool showFaceContour;
  final int filterIndex;

  const FaceCamera(
      {Key key,
      this.faces,
      this.camera,
      this.showFaceContour = false,
      this.filterIndex = 1})
      : super(key: key);

  @override
  _FaceCameraState createState() => _FaceCameraState();
}

class _FaceCameraState extends State<FaceCamera> {
  Size _imageSize;

  @override
  Widget build(BuildContext context) {
    _imageSize = Size(
      widget.camera.value.previewSize.height,
      widget.camera.value.previewSize.width,
    );

    final Size _size = MediaQuery.of(context).size;
    final _deviceRatio = _size.width / _size.height;

    int filterIndex = widget.filterIndex;

    return Stack(
      children: <Widget>[
        CameraPreview(widget.camera),
        widget.showFaceContour
            ? _getFaceContourPaint(widget.faces, widget.camera)
            : Container(),
//        _getLeftEarStickerWidget(widget.faces, widget.filterIndex),
        _getBottomStickerWidget(widget.faces, filterIndex),
        _getTopStickerWidget(widget.faces, filterIndex),
        _getMouthStickerWidget(widget.faces, filterIndex, _size),
      ],
    );
  }

  Widget _getMouthStickerWidget(
      List<Face> faces, int filterIndex, Size widgetSize) {
    try {
      double ratio = (faces[0].boundingBox).height / 180;
      final ARFilter arFilter =
          _getMouseARFilter(filterIndex, ratio, widgetSize);

      if (arFilter == null) {
        return Container();
      }

      writeLog("<MouthFilter> (${arFilter.offset.dx}, ${arFilter.offset.dy})");

      Widget stickerWidgets = new Positioned(
          left: arFilter.offset.dx,
          top: arFilter.offset.dy,
          child: new Stack(
            children: <Widget>[
              for (var assetName in arFilter.assetNames)
                _getStickerWidget(assetName, arFilter.width, arFilter.height),
            ],
          ));
      return stickerWidgets;
    } catch (e) {
      return Text("");
    }
  }

  Widget _getLeftEarStickerWidget(
      List<Face> faces, int filterIndex, Size widgetSize) {
    if (faces == null) {
      return new Text("");
    }

    final ARFilter arFilter = _getLeftEarARFilter(filterIndex, widgetSize);

    if (arFilter == null) {
      return Container();
    }

    Widget stickerWidgets = new Positioned(
        right: arFilter.offset.dx,
        top: arFilter.offset.dy,
        child: new Stack(
          children: <Widget>[
            for (var assetName in arFilter.assetNames)
              _getStickerWidget(assetName, arFilter.width, arFilter.height),
          ],
        ));

    return stickerWidgets;
  }

  Widget _getBottomStickerWidget(List<Face> faces, int filterIndex) {
    final ARFilter arFilter = _getBottomARFilter(filterIndex);

    try {
      final face = faces[0].boundingBox;

      Widget stickerWidgets = new Positioned(
          child: new Stack(
            children: <Widget>[
              for (var assetName in arFilter.assetNames)
                _getStickerWidget(assetName, arFilter.width, arFilter.height,
                    boxfit: BoxFit.fill),
            ],
          ));

      return stickerWidgets;
    } catch (e) {
      return Container();
    }
  }

  Widget _getTopStickerWidget(List<Face> faces, int filterIndex) {
    final ARFilter arFilter = _getBottomARFilter(filterIndex);

    try {
      final face = faces[0].boundingBox;
      writeLog("<Face> (${face.left}, ${face.top}, ${face.right}, ${face.bottom})");

      Widget stickerWidgets = new Positioned(
          child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationZ(math.pi),
              child: new Stack(
                children: <Widget>[
                  for (var assetName in arFilter.assetNames)
                    _getStickerWidget(assetName, arFilter.width, arFilter.height,
                        boxfit: BoxFit.fill),
                ],
              )));
      return stickerWidgets;
    } catch (e) {
      return Container();
    }
  }

  ARFilter _getMouseARFilter(int filterIndex, double ratio, Size widgetSize) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.Mouse;

    final Offset mouthCenterPoint =
        _getMouthCenterPoint(widget.faces, widgetSize);
    if (mouthCenterPoint == null) {
      return null;
    }

    switch (filterIndex) {
      case 1:
        arFilter.assetNames.add("assets/say_m01.webp");
        arFilter.width = 200;
        arFilter.height = 400;
        break;
      case 2:
        arFilter.assetNames.add("assets/say_m02.webp");
        arFilter.width = 200;
        arFilter.height = 400;
        break;
      case 3:
        arFilter.assetNames.add("assets/say_m03.webp");
        arFilter.width = 200;
        arFilter.height = 400;
        break;
      default:
        return null;
    }

    arFilter.width *= ratio;
    arFilter.height *= ratio;

    final double left = (filterIndex == 2)
        ? mouthCenterPoint.dx
        : mouthCenterPoint.dx - (arFilter.width / 2) + 10;
    final double top = mouthCenterPoint.dy - (arFilter.height / 2) - 10;
    arFilter.offset = Offset(left, top);

    return arFilter;
  }

  ARFilter _getBottomARFilter(int filterIndex) {
    ARFilter arFilter = new ARFilter();

    switch (filterIndex) {
      case 2:
        arFilter.assetNames.add("assets/bottom_m02.webp");
        arFilter.width = 600;
        arFilter.height = 1200;
        break;
      case 3:
        arFilter.assetNames.add("assets/bottom_m03.webp");
        arFilter.width = 600;
        arFilter.height = 1200;
        break;
      default:
        return null;
    }

    return arFilter;
  }

  ARFilter _getLeftEarARFilter(int filterIndex, Size widgetSize) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.LeftEar;

    final Offset leftEarPoint = _getLeftEarPoint(widget.faces, widgetSize);
    if (leftEarPoint == null) {
      return null;
    }

    if (_getRightEarPoint(widget.faces, widgetSize).dx -
            _getNosePoint(widget.faces, widgetSize).dx >=
        40) {
      return null;
    }

    switch (filterIndex) {
      case 2:
        arFilter.assetNames.add("assets/hear_m02_once.webp");
        arFilter.width = 200;
        arFilter.height = 100;
        break;
      case 3:
        arFilter.assetNames.add("assets/hear_m03_once.webp");
        arFilter.width = 220;
        arFilter.height = 150;
        break;
      case 4:
        arFilter.assetNames.add("assets/hear_m04_once.webp");
        arFilter.width = 220;
        arFilter.height = 150;
        break;
      case 5:
        arFilter.assetNames.add("assets/hear_m05_once.webp");
        arFilter.width = 300;
        arFilter.height = 250;
        break;
      default:
        return null;
    }

    final double right = (filterIndex == 1) ? 0 : leftEarPoint.dx * -1 + 410;
    final double top =
        (filterIndex == 1) ? 0 : leftEarPoint.dy - (arFilter.height / 2) - 20;
    arFilter.offset = Offset(right, top);

    return arFilter;
  }

  Widget _getStickerWidget(String assetName, double width, double height,
      {BoxFit boxfit = BoxFit.contain}) {
    Widget stickerWidget = Positioned(
      child: new Container(
//        color: Colors.blue,
          child: new Image(
        fit: boxfit,
        image: new AssetImage(assetName),
        width: width,
        height: height,
        alignment: Alignment.center,
      )..image.evict()),
    );

    return stickerWidget;
  }

  Widget _getFaceContourPaint(List<Face> faces, CameraController camera) {
    if (faces == null || camera == null) return Text("");

    return new CustomPaint(
      size: Size(
        camera.value.previewSize.height,
        camera.value.previewSize.width,
      ),
      painter: FaceContourPainter(
          Size(
            camera.value.previewSize.height,
            camera.value.previewSize.width,
          ),
          faces,
          camera.description.lensDirection),
    );
  }

  Offset _getNosePoint(List<Face> faces, Size widgetSize) {
    if (faces == null) return null;

    try {
      Face face = faces[0];
      return _scalePoint(
          offset: face.getContour(FaceContourType.noseBottom).positionsList[1],
          widgetSize: widgetSize,
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return null;
    }
  }

  Offset _getRightEarPoint(List<Face> faces, Size widgetSize) {
    if (faces == null) return null;

    try {
      Face face = faces[0];
      return _scalePoint(
          offset: face.getContour(FaceContourType.face).positionsList[27],
          widgetSize: widgetSize,
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return null;
    }
  }

  Offset _getLeftEarPoint(List<Face> faces, Size widgetSize) {
    if (faces == null) return null;

    try {
      Face face = faces[0];
      return _scalePoint(
          offset: face.getContour(FaceContourType.face).positionsList[9],
          widgetSize: widgetSize,
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return null;
    }
  }

  Offset _getMouthCenterPoint(List<Face> faces, Size widgetSize) {
    final double mouthOpenThreshold = 15;

    if (faces == null) return null;

    try {
      Face face = faces[0];
      Offset upperLipBottom =
          face.getContour(FaceContourType.upperLipBottom).positionsList[4];
      Offset lowerLipTop =
          face.getContour(FaceContourType.lowerLipTop).positionsList[4];

      double offsetMouse = lowerLipTop.dy - upperLipBottom.dy;

      if (offsetMouse > mouthOpenThreshold) {
        return _scalePoint(
            offset: (upperLipBottom + lowerLipTop) / 2,
            widgetSize: widgetSize,
            cameraLensDirection: CameraLensDirection.front);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  Offset _scalePoint(
      {Offset offset,
      @required Size widgetSize,
      CameraLensDirection cameraLensDirection}) {
    final double scaleX = widgetSize.width / _imageSize.width;
    final double scaleY = widgetSize.height / _imageSize.height;

    if (cameraLensDirection == CameraLensDirection.front) {
      return Offset(
          widgetSize.width - (offset.dx * scaleX), offset.dy * scaleY);
    }
    return Offset(offset.dx * scaleX, offset.dy * scaleY);
  }
}
