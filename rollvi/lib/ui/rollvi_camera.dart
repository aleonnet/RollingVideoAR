import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
//import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'package:rollvi/ui/face_painter.dart';
import 'dart:math' as math;


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

  final Audio mouthAudio = Audio();
  final Audio bottomAudio = Audio();

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

    final Size _size = MediaQuery.of(context).size;
    final _deviceRatio = _size.width / _size.height;

    int filterIndex = widget.filterIndex;

    return Stack(
      children: <Widget>[
        Container(
          child: CameraPreview(widget.camera),
        ),
        widget.showFaceContour ? _getFaceContourPaint(widget.faces, widget.camera) : Container(),
        _getBottomStickerWidget(widget.faces, widget.filterIndex),
        _getTopStickerWidget(widget.faces, widget.filterIndex),
        _getLeftEarStickerWidget(widget.faces, widget.filterIndex, _size),
        _getMouthStickerWidget(widget.faces, widget.filterIndex, _size),
      ],
    );
  }

  Widget _getMouthStickerWidget(List<Face> faces, int filterIndex, Size widgetSize) {
    if (faces == null) {
      return Text("");
    }

    try {
      double ratio = (faces[0].boundingBox).height / 300;
      final ARFilter arFilter = _getMouseARFilter(filterIndex, ratio, widgetSize);

      if (arFilter == null) {
        mouthAudio.stop();
        return Container();
      }

      if (filterIndex == 1 || filterIndex == 2 || filterIndex == 3) {
        mouthAudio.play('say_0$filterIndex.wav', playbackRate: 1.1);
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
    } catch (e) {
      return Text("");
    }
  }

  Widget _getLeftEarStickerWidget(List<Face> faces, int filterIndex, Size widgetSize) {
    if (faces == null) {
      return new Text("");
    }

    try {
      double ratio = (faces[0].boundingBox).height / 180;

      final ARFilter arFilter = _getLeftEarARFilter(filterIndex, ratio, widgetSize);

      Widget stickerWidgets = new Positioned(
          right: arFilter.offset.dx,
          top: arFilter.offset.dy,
          child: new Stack(
            children: <Widget>[
              for (var assetName in arFilter.assetNames)
                _getStickerWidget(assetName, arFilter.width, arFilter.height, once: true),
            ],
          ));

      return stickerWidgets;

    } catch (e) {
      return Container();
    }
  }

  Widget _getBottomStickerWidget(List<Face> faces, int filterIndex) {
    final ARFilter arFilter = _getBottomARFilter(filterIndex);

    try {
      final face = faces[0].boundingBox;

      if (filterIndex == 2 || filterIndex == 3) {
        bottomAudio.play('bottom_0$filterIndex.wav');
      }

      Widget stickerWidgets = new Positioned(
          child: new Stack(
            children: <Widget>[
              for (var assetName in arFilter.assetNames)
                _getStickerWidget(assetName, arFilter.width, arFilter.height,
                    boxfit: BoxFit.fitWidth),
            ],
          ));

      return stickerWidgets;
    } catch (e) {
      bottomAudio.stop();
      return Container();
    }
  }

  Widget _getTopStickerWidget(List<Face> faces, int filterIndex) {
    final ARFilter arFilter = _getBottomARFilter(filterIndex);

    try {
      final face = faces[0].boundingBox;

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

  ARFilter _getBottomARFilter(int filterIndex) {
    ARFilter arFilter = new ARFilter();

    switch (filterIndex) {
      case 2:
        arFilter.assetNames.add("assets/bottom_02.webp");
        arFilter.width = 400;
        arFilter.height = 600;
        break;
      case 3:
        arFilter.assetNames.add("assets/bottom_03.webp");
        arFilter.width = 800;
        arFilter.height = 1200;
        break;
      default:
        return null;
    }

    return arFilter;
  }

  ARFilter _getMouseARFilter(int filterIndex, double ratio, Size widgetSize) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.Mouse;

    final Offset mouthCenterPoint = _getMouthCenterPoint(widget.faces, widgetSize);
    if (mouthCenterPoint == null) {
      return null;
    }

    switch(filterIndex) {
      case 1:
        arFilter.assetNames.add("assets/say_01.webp");
        arFilter.width = 250;
        arFilter.height = 500;
        break;
      case 2:
        arFilter.assetNames.add("assets/say_02.webp");
        arFilter.width = 250;
        arFilter.height = 500;
        break;
      case 3:
        arFilter.assetNames.add("assets/say_03.webp");
        arFilter.width = 250;
        arFilter.height = 500;
        break;
      case 4:
        arFilter.assetNames.add("assets/say_04.webp");
        arFilter.width = 200;
        arFilter.height = 100;
        break;
      case 5:
        arFilter.assetNames.add("assets/say_05.webp");
        arFilter.width = 300;
        arFilter.height = 250;
        break;
      case 6:
        arFilter.assetNames.add("assets/say_06.webp");
        arFilter.width = 450;
        arFilter.height = 400;
        break;
      case 7:
        arFilter.assetNames.add("assets/say_07.webp");
        arFilter.width = 450;
        arFilter.height = 400;
        break;
      case 8:
        arFilter.assetNames.add("assets/say_08.webp");
        arFilter.width = 450;
        arFilter.height = 600;
        break;
      default:
        return null;
    }

    double left = 0;
    double top = 0;

    if (filterIndex == 8) {
      left = mouthCenterPoint.dx - (arFilter.width / 2);
      top = mouthCenterPoint.dy - (arFilter.height / 2);
    }
    else if (filterIndex == 1 || filterIndex == 2 || filterIndex == 3) {
      arFilter.width *= ratio;
      arFilter.height *= ratio;

      left = mouthCenterPoint.dx - (arFilter.width / 2);
      top = mouthCenterPoint.dy - (arFilter.height / 2) - 40;
    }
    else {
      left = mouthCenterPoint.dx;
      top = mouthCenterPoint.dy - (arFilter.height / 2) - 60;
    }

    arFilter.offset = Offset(left, top);

    return arFilter;
  }

  ARFilter _getLeftEarARFilter(int filterIndex, double ratio, Size widgetSize) {
    ARFilter arFilter = new ARFilter();
    arFilter.location = FilterLocation.LeftEar;

    final Offset leftEarPoint = _getLeftEarPoint(widget.faces, widgetSize);
    if (leftEarPoint == null) {
      return null;
    }

    double offset = _getRightEarPoint(widget.faces, widgetSize).dx - _getNosePoint(widget.faces, widgetSize).dx;
    if (offset >= _leftEarOffset) {
      return null;
    }

    switch(filterIndex) {
      case 5:
        arFilter.assetNames.add("assets/hear_05.webp");
        arFilter.width = 200;
        arFilter.height = 100;
        break;
      case 6:
        arFilter.assetNames.add("assets/hear_06.webp");
        arFilter.width = 220;
        arFilter.height = 150;
        break;
      case 7:
        arFilter.assetNames.add("assets/hear_07.webp");
        arFilter.width = 220;
        arFilter.height = 150;
        break;
      case 8:
        arFilter.assetNames.add("assets/hear_08.webp");
        arFilter.width = 300;
        arFilter.height = 250;
        break;
      default:
        return null;
    }

//    arFilter.width *= ratio;
//    arFilter.height *= ratio;

    final double right = leftEarPoint.dx * -1 + widgetSize.width;
    final double top = leftEarPoint.dy - (arFilter.height / 2) - 30;

    arFilter.offset = Offset(right, top);

    return arFilter;
  }


  Widget _getStickerWidget(String assetName, double width, double height,
      {BoxFit boxfit = BoxFit.contain, bool once = false}) {

    if (!once) {
      return Positioned(
        child: new Container(
//        color: Colors.blue,
            child: new Image(
              fit: boxfit,
              image: new AssetImage(assetName),
              width: width,
              height: height,
              alignment: Alignment.center,
            )),
      );
    }
    else {
      return Positioned(
        child: new Container(
//        color: Colors.blue,
            child: new Image(
              fit: boxfit,
              image: new AssetImage(assetName),
              width: width,
              height: height,
              alignment: Alignment.center,
            )..image.evict()
        ),
      );
    }
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
            offset: (upperLipBottom + lowerLipTop) / 2 ,
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


class Audio {
  final AudioCache cache = AudioCache();
  AudioPlayer player;

  Audio() {
    player = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  }

  void play(String assetName, {double playbackRate = 0.9}) async {
    if (player.state != AudioPlayerState.PLAYING) {
      player = await cache.play(assetName);
      player.setPlaybackRate(playbackRate: playbackRate);
    }
  }

  void stop() {
    player.stop();
  }
}