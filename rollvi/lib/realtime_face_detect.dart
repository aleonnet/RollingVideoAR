import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'face_painter.dart';

import 'utils.dart';

class RealtimeFaceDetect extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<RealtimeFaceDetect> {
  final GlobalKey previewContainer = new GlobalKey();

  final FaceDetector faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
          enableClassification: false,
          enableLandmarks: false,
          enableContours: true,
          enableTracking: false));

  List<Face> _faces;
  CameraController _camera;
  bool _isDetecting = false;
  CameraLensDirection _cameraDirection = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription description = await availableCameras().then(
        (List<CameraDescription> cameras) => cameras.firstWhere(
            (CameraDescription camera) =>
                camera.lensDirection == _cameraDirection));

    ImageRotation rotation =
        rotationIntToImageRotation(description.sensorOrientation);

    _camera = CameraController(description, ResolutionPreset.high);

    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      _detectFaces(image, rotation).then(
        (dynamic result) {
          setState(() {
            _faces = result;
          });

          _isDetecting = false;
        },
      ).catchError((_) {
        _isDetecting = false;
      });
    });
  }

  _detectFaces(CameraImage cameraImage, ImageRotation rotation) async {
    final image = FirebaseVisionImage.fromBytes(
      concatenatePlanes(cameraImage.planes),
      buildMetaData(cameraImage, rotation),
    );

    List<Face> faces = await faceDetector.processImage(image);
    return faces;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROLLVI'),
        backgroundColor: Colors.redAccent,
      ),
      body:RepaintBoundary (
        key: previewContainer,
        child:  ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            widthFactor: 1.0,
            heightFactor: 0.8, // 0.56
            child: AspectRatio(
              aspectRatio: 9 / 15,
              child: _camera == null
                  ? Container(color: Colors.black)
                  : FaceCamera(faces: _faces, camera: _camera),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.fiber_manual_record),
        onPressed: () async {
          try {
            final path = join(
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            print(path);

//            Navigator.push(context, MaterialPageRoute(
//                  builder: (context) => DisplayPictureScreen(imagePath: '/data/user/0/kr.hispace.rollvi/app_flutter/screenshot.png'),
//                ));

            await _capture().then(
              print("Caputre Complete"),
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(imagePath: '/data/user/0/kr.hispace.rollvi/app_flutter/screenshot.png'),
                ))
            );

          } catch (e) {
            print(e);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  _capture() async {
    print("START CAPTURE");
    var renderObject = previewContainer.currentContext.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      var boundary = renderObject;
      ui.Image image = await boundary.toImage();
      final directory = (await getApplicationDocumentsDirectory()).path;
      ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      print(pngBytes);
      File imgFile = new File('$directory/screenshot.png');
      imgFile.writeAsBytes(pngBytes);
      print("FINISH CAPTURE ${imgFile.path}");
    }
  }

  takeScreenShot() async{
    RenderRepaintBoundary boundary = previewContainer.currentContext.findRenderObject();
    var image = await boundary.toImage();
    var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    var pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);
  }


  @override
  void dispose() async {
    super.dispose();
    await _camera.stopImageStream();
    await _camera.dispose();
  }
}

// 사용자가 촬영한 사진을 보여주는 위젯
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}

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
//        key: previewContainer,
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
            (faces != null)
                ? new Positioned.fill(
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
                        )).dy,
//                    child: Carousel(images: [
//                      new Image(
//                        image: new AssetImage("assets/water.gif"),
//                        alignment: Alignment.topLeft,
//                      ),
//                      new Image(
//                        image: new AssetImage("assets/rainbow.gif"),
//                        alignment: Alignment.topLeft,
//                      ),
//                    ], autoplay: false))
                      child: new Image(
                          image: new AssetImage("assets/water.gif"),
                          alignment: Alignment.topLeft,
                        ))
                : new Text("aaa")
          ],
        ));
  }

  Offset _getLipBottomPoint(List<Face> faces, Size imageSize) {
    if (faces == null) return Offset(-500, -500);
    try {
      Offset upperLipBottom = faces[0].getContour(FaceContourType.upperLipBottom).positionsList[4];
      Offset lowerLipTop = faces[0].getContour(FaceContourType.lowerLipTop).positionsList[4];

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
