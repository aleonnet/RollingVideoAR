import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'package:rollvi/ui/face_painter.dart';


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

class RollviCamera extends StatefulWidget {
  final List<Face> faces;
  final CameraController camera;
  final bool showFaceContour;
  final int filterIndex;

  const RollviCamera(
      {Key key, this.faces, this.camera, this.showFaceContour = false, this.filterIndex = 1})
      : super(key: key);

  @override
  _FaceCameraState createState() => _FaceCameraState();
}

class _FaceCameraState extends State<RollviCamera> {

  final double _leftEarOffset = 70;
  Size _imageSize;

  @override
  Widget build(BuildContext context) {

    try {
      _imageSize = Size(
        widget.camera.value.previewSize.height,
        widget.camera.value.previewSize.width,
      );
    } catch (e) {
      _imageSize = Size(0.0, 0.0);
    }

    return Stack(
      children: <Widget>[
        CameraPreview(widget.camera),
        widget.showFaceContour ? _getFaceContourPaint(widget.faces, widget.camera) : Container(),
        _getLeftEarStickerWidget(widget.faces, widget.filterIndex),
        _getMouthStickerWidget(widget.faces, widget.filterIndex),
      ],
    );
  }

  Widget _getMouthStickerWidget(List<Face> faces, int filterIndex) {
    if (faces == null) {
      return Text("");
    }

    final ARFilter arFilter = _getMouseARFilter(filterIndex);

    if (arFilter == null) {
      return Container();
    }

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
  }

  Widget _getLeftEarStickerWidget(List<Face> faces, int filterIndex) {
    if (faces == null) {
      return new Text("");
    }

    final ARFilter arFilter = _getLeftEarARFilter(filterIndex);

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

  ARFilter _getMouseARFilter(int filterIndex) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.Mouse;

    final Offset mouthCenterPoint = _getMouthCenterPoint(widget.faces);
    if (mouthCenterPoint == null) {
      return null;
    }

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
      default:
        return null;
    }

    final double left = (filterIndex == 5) ?  mouthCenterPoint.dx - (arFilter.width / 2) : mouthCenterPoint.dx;
    final double top = mouthCenterPoint.dy - (arFilter.height / 2) + 20;
    arFilter.offset = Offset(left, top);

    return arFilter;
  }

  ARFilter _getLeftEarARFilter(int filterIndex) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.LeftEar;

    final Offset leftEarPoint = _getLeftEarPoint(widget.faces);
    if (leftEarPoint == null) {
      return null;
    }

    double offset = _getRightEarPoint(widget.faces).dx - _getNosePoint(widget.faces).dx;
    if (offset >= _leftEarOffset) {
      return null;
    }

    switch(filterIndex) {
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
    final double top = (filterIndex == 1) ? 0 : leftEarPoint.dy - (arFilter.height / 2) + 20;
    arFilter.offset = Offset(right, top);

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
      )..image.evict()
      ),
    );

    return stickerWidget;
  }

  Widget _getFaceContourPaint(List<Face> faces, CameraController camera) {
    if (faces == null || camera == null) return Text("");

    try {
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
    } catch (e) {
      return new Container();
    }
  }

  Offset _getNosePoint(List<Face> faces) {
    if (faces == null) return null;

    try {
      Face face = faces[0];
      return _scalePoint(
          offset: face.getContour(FaceContourType.noseBottom).positionsList[1],
          widgetSize: Size(411.4, 685.7),
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return null;
    }
  }

  Offset _getRightEarPoint(List<Face> faces) {
    if (faces == null) return null;

    try {
      Face face = faces[0];
      return _scalePoint(
          offset: face.getContour(FaceContourType.face).positionsList[27],
          widgetSize: Size(411.4, 685.7),
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return null;
    }
  }

  Offset _getLeftEarPoint(List<Face> faces) {
    if (faces == null) return null;

    try {
      Face face = faces[0];
      return _scalePoint(
          offset: face.getContour(FaceContourType.face).positionsList[9],
          widgetSize: Size(411.4, 685.7),
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return null;
    }
  }

  Offset _getMouthCenterPoint(List<Face> faces) {
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
            offset: (upperLipBottom + lowerLipTop) / 2 ,
            widgetSize: Size(411.4, 685.7),
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
