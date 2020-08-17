import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'face_painter.dart';


class FaceCamera extends StatelessWidget {
  final List<Face> faces;
  final CameraController camera;
  final bool cameraEnabled;

  const FaceCamera(
      {Key key, this.faces, this.camera, this.cameraEnabled = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: const BoxConstraints.expand(),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            cameraEnabled
                ? CameraPreview(camera)
                : Container(color: Colors.black),
            (faces != null)
                ? CustomPaint(
              painter: FaceContourPainter(
                  Size(
                    camera.value.previewSize.height,
                    camera.value.previewSize.width,
                  ),
                  faces,
                  camera.description.lensDirection),
            )
                : const Text('No results!'),
//          new Positioned.fill(
//              left: 50,
//              top: 100,
//            child: new Image(
//                image: new AssetImage("assets/rainbow.gif")
//            ),
//          )
          ],
        ));
  }
}
