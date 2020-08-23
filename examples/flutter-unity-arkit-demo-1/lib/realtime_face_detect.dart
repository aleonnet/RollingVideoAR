import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'face_painter.dart';
import 'package:photofilters/photofilters.dart';

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

  CameraImage _savedImage;

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
            _savedImage = image;

            Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
            Offset leftEar = _getLeftEarPoint(_faces, imageSize);
            Offset lipBottom = _getLipCenterPoint(_faces, imageSize);

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

  Offset _getLipCenterPoint(List<Face> faces, Size imageSize) {
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROLLVI'),
        backgroundColor: Colors.redAccent,
      ),
      body: RepaintBoundary(
        key: previewContainer,
        child: _camera == null
            ? Container(color: Colors.black)
            : FaceCamera(faces: _faces, camera: _camera),
//        child: ClipRect(
//          child: Align(
//            alignment: Alignment.topCenter,
//            widthFactor: 1.0,
//            heightFactor: 1.0, // 0.8, 0.56
//            child: AspectRatio(
//              aspectRatio: 1, // 9 / 15
//              child: _camera == null
//                  ? Container(color: Colors.black)
//                  : FaceCamera(faces: _faces, camera: _camera),
//            ),
//          ),
//        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.fiber_manual_record),
        onPressed: () async {
          try {
            final path = join(
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            await _capture().then((path) => {
                  imageCache.clear(),
                  print("Capture Complete : $path"),
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DisplayPictureScreen(imagePath: path)))
                });
          } catch (e) {
            print(e);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<String> _capture() async {
    print("START CAPTURE");
    var renderObject = previewContainer.currentContext.findRenderObject();
    print(renderObject);
    if (renderObject is RenderRepaintBoundary) {
      var boundary = renderObject;
      ui.Image image = await boundary.toImage();
//      final directory = (await getApplicationDocumentsDirectory()).path;
      final directory = (await getExternalStorageDirectory()).path;
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      File imgFile = new File('$directory/screenshot.png');
      imgFile.writeAsBytesSync(pngBytes);
      print(pngBytes);
      print("FINISH CAPTURE ${imgFile.path}");

      return imgFile.path;
    } else {
      print("not renderRepaintBoundary");
    }
    return null;
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
        constraints: const BoxConstraints.expand(),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            cameraEnabled
                ? CameraPreview(camera)
                : Container(color: Colors.black),
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
                    right: _getLeftEarPoint(
                                faces,
                                Size(
                                  camera.value.previewSize.height,
                                  camera.value.previewSize.width,
                                )).dx *
                            -1 +
                        420,
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

  static imglib.Image _convertCameraImage(CameraImage image) {
    int width = image.width;
    int height = image.height;

    var img = imglib.Image(width, height); // Create Image buffer
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data[index] = hexFF | (b << 16) | (g << 8) | r;
      }
    }
    // Rotate 90 degrees to upright
    var img1 = imglib.copyRotate(img, 90);
    return img1;
  }
}

