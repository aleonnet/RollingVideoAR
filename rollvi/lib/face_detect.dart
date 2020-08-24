import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'package:photofilters/photofilters.dart';
import 'package:rollvi/face_preview.dart';

import 'face_camera.dart';
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

  final int _maxTime = 5;
  bool isRecording = false;
  Timer _timer;
  List<imglib.Image> _imageSequence;


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() async {
    super.dispose();
    stopRecording();
    await _camera.stopImageStream();
    await _camera.dispose();
  }

  void stopRecording() {
    isRecording = false;
    _timer.cancel();
    _imageSequence.clear();
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
      _savedImage = image;

      if (_isDetecting) return;

      _isDetecting = true;

      _detectFaces(image, rotation).then(
        (dynamic result) {
          setState(() {
            _faces = result;

            if (isRecording) {
              _imageSequence.add(_convertCameraImage(image));
            }
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
            if (isRecording) {
              return;
            }

            isRecording = true;

            int _time = _maxTime;

            _timer = new Timer.periodic(
                Duration(seconds: 1),
                    (timer) {
                      if (_time < 1) {
                        stopRecording();
                      } else {
                        _time -= 1;
                      }
                    });

            imglib.Image capturedImage = _convertCameraImage(_savedImage);
            await _capture().then((path) => {
                  imageCache.clear(),
                  print("Capture Complete : $path"),
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FacePreview(
                              cameraImg: capturedImage,
                              cameraSequence: _imageSequence,
                              imagePath: path)))
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
//    final directory = (await getExternalStorageDirectory()).path;
//    File imgFile = new File('$directory/screenshot.png');

    final path = join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now()}.png',
    );

    var renderObject = previewContainer.currentContext.findRenderObject();
    print(renderObject);
    if (renderObject is RenderRepaintBoundary) {
      ui.Image image = await renderObject.toImage();

      ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      File imgFile = new File(path);
      imgFile.writeAsBytesSync(pngBytes);

      print("FINISH CAPTURE ${imgFile.path}");

      return imgFile.path;
    }

    return null;
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
    var img1 = imglib.copyRotate(img, -90);
    return img1;
  }
}
