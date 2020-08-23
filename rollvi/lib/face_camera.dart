import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class FaceCamera extends StatelessWidget {
  final List<Face> faces;
  final CameraController camera;

  const FaceCamera(
      {Key key, this.faces, this.camera})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: const BoxConstraints.expand(),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CameraPreview(camera),
//            (faces != null)
//                ? CustomPaint(
//                    painter: FaceContourPainter(
//                        Size(
//                          camera.value.previewSize.height,
//                          camera.value.previewSize.width,
//                        ),
//                        faces,
//                        camera.description.lensDirection),
//                  )
//                : const Text('No results!'),
            (faces != null)
                ? new Positioned(
                width: 200,
                right: _scalePoint(
                    offset: faces[0].getContour(FaceContourType.face).positionsList[9],
                    imageSize: Size(
                      camera.value.previewSize.width,
                      camera.value.previewSize.height,
                    ),
                    widgetSize: Size(411.4, 685.7),
                    cameraLensDirection: CameraLensDirection.front).dy,
                top: _getLeftEarPoint(
                    faces,
                    Size(
                      camera.value.previewSize.height,
                      camera.value.previewSize.width,
                    )).dy -
                    150,
                child: new Stack(
                  children: <Widget>[
                    Positioned(
                      child: new Container(
                          child: new Image(
                            image: new AssetImage("assets/hear_text.gif"),
                            height: 300,
                            alignment: Alignment.center,
                          )),
                    ),
                    Positioned(
                      child: new Container(
                          child: new Image(
                            image: new AssetImage("assets/hear_heart.gif"),
                            height: 300,
                            alignment: Alignment.center,
                          )),
                    )
                  ],
                ))
                : new Text(""),
            (faces != null)
                ? new Positioned(
                width: 200,
                left: _getLipBottomPoint(
                    faces,
                    Size(
                      camera.value.previewSize.height,
                      camera.value.previewSize.width,
                    )).dx,
                top: _getLipBottomPoint(
                    faces,
                    Size(
                      camera.value.previewSize.height,
                      camera.value.previewSize.width,
                    )).dy -
                    150,
                child: new Stack(
                  children: <Widget>[
                    Positioned(
                      child: new Container(
                          child: new Image(
                            image: new AssetImage("assets/say_text.gif"),
                            height: 300,
                            alignment: Alignment.center,
                          )),
                    ),
                    Positioned(
                      child: new Container(
                          child: new Image(
                            image: new AssetImage("assets/say_test01.webp"),
                            height: 300,
                            alignment: Alignment.center,
                          )),
                    ),
                  ],
                ))
                : new Text("aaa")
          ],
        ));
  }

  Offset _getLeftEarPoint(List<Face> faces, Size imageSize) {
    if (faces == null) return Offset(-500, -500);
    try {
      return _scalePoint(
          offset: faces[0].getContour(FaceContourType.face).positionsList[9],
          imageSize: imageSize,
          widgetSize: Size(411.4, 685.7),
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return Offset(-500, -500);
    }
  }

  Offset _getLipBottomPoint(List<Face> faces, Size imageSize) {
    if (faces == null) return Offset(-500, -500);
    try {
      Offset upperLipBottom =
      faces[0].getContour(FaceContourType.upperLipBottom).positionsList[4];
      Offset lowerLipTop =
      faces[0].getContour(FaceContourType.lowerLipTop).positionsList[4];

      double offsetMouse = lowerLipTop.dy - upperLipBottom.dy;

      if (offsetMouse > 15) {


//        isMouseOpen = true;
        print("Open Mouse");
      } else {
//        isMouseOpen = false;
      }

      return _scalePoint(
          offset: (upperLipBottom + lowerLipTop) / 2.0,
          imageSize: imageSize,
          widgetSize: Size(411.4, 685.7),
          cameraLensDirection: CameraLensDirection.front);
    } catch (e) {
      return Offset(-500, -500);
    }
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
