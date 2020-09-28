import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:darwin_camera/darwin_camera.dart';
import 'package:rollvi_exhibit/image_preview.dart';
import 'package:rollvi_exhibit/image_sequence_preview.dart';
import 'package:rollvi_exhibit/video_preview.dart';

import 'face_camera.dart';
import 'utils.dart';

enum CaptureType {
  Image,
  Video,
  ImageSequence,
}

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

  final int _maxTime = 3;
  bool isRecording = false;
  Timer _timer;
  CameraImage _lastImage;
  List<imglib.Image> _imageSequence;

  CaptureType _captureType = CaptureType.Video;
  int _selectedFilter = 1;
  bool _showShootButton = true;
  bool _showFaceContour = false;

  @override
  void initState() {
    super.initState();
    _imageSequence = new List<imglib.Image>();
    _initialize();
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
  }

  void _initialize() {
    isRecording = false;
    if (_timer != null) _timer.cancel();
    if (_imageSequence.isNotEmpty) _imageSequence.clear();

    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription description = await availableCameras().then(
        (List<CameraDescription> cameras) => cameras.firstWhere(
            (CameraDescription camera) =>
                camera.lensDirection == CameraLensDirection.front));

    ImageRotation rotation =
        rotationIntToImageRotation(description.sensorOrientation);

    _camera = CameraController(description, ResolutionPreset.high);

    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      _lastImage = image;

      if (_isDetecting) return;

      _isDetecting = true;

      _detectFaces(image, rotation).then(
        (dynamic result) {
          setState(() {
            _faces = result;

            if (_captureType == CaptureType.ImageSequence &&
                isRecording == true) {
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
    final Size _size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
//            RepaintBoundary(
//              key: previewContainer,
//              child: _camera == null
//                  ? Container(color: Colors.black)
//                  : FaceCamera(
//                  faces: _faces,
//                  camera: _camera,
//                  showFaceContour: _showFaceContour,
//                  filterIndex: _selectedFilter),
//            ),
            RepaintBoundary(
              key: previewContainer,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child:  (_camera != null) ? Align(
                  alignment: Alignment.center,
//                  widthFactor: 1,
//                  heightFactor: _camera.value.aspectRatio,
                  child: _camera == null
                      ? Container(
                    color: Colors.black,
                  )
                      : AspectRatio(
                    aspectRatio: _camera.value.aspectRatio,
                    child: FaceCamera(
                        faces: _faces,
                        camera: _camera,
                        showFaceContour: _showFaceContour,
                        filterIndex: _selectedFilter),
                  ),
                ) : Container(),
              ),
            ),


            Container(
              width: 200,
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.only(left: _size.width - 200, bottom: 10),
              child: Opacity(
                opacity: 0.8,
                child: FlatButton(
                  child: Image.asset('assets/rollvi_logo_v_wh.png'),
                  onLongPress: () {
                    _selectedFilter =
                    (_selectedFilter > 2) ? 1 : _selectedFilter += 1;

                    writeLog("(Select Filter) $_selectedFilter");
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getFilterIcon(int index) {
    Color color = Colors.grey.shade700;
    switch (index) {
      case 1:
        return Icon(
          Icons.looks_one,
          color: color,
        );
      case 2:
        return Icon(
          Icons.looks_two,
          color: color,
        );
      case 3:
        return Icon(
          Icons.looks_3,
          color: color,
        );
      case 4:
        return Icon(
          Icons.looks_4,
          color: color,
        );
      case 5:
        return Icon(
          Icons.looks_5,
          color: color,
        );
      default:
        return Icon(
          Icons.settings,
          color: color,
        );
    }
  }

  Widget _getRecordButton(BuildContext context) {
    FloatingActionButton recordButton = FloatingActionButton(
      child: Icon(Icons.camera),
      onPressed: () async {
        try {
          // for image stream
          isRecording = true;

          // for recording video
          String videoPath = '';
          if (_captureType == CaptureType.Video) {
            await _camera.stopImageStream();
            _startVideoRecording().then((String filePath) {
              if (filePath != null) {
                print("Recording Start");
                setState(() {
                  videoPath = filePath;
                });
              }
            });
          }

          if (_captureType == CaptureType.Image) {
            imglib.Image capturedImage = _convertCameraImage(_lastImage);
            _capture().then((path) => {
                  imageCache.clear(),
                  print("Capture Complete : $path"),
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ImagePreview(
                                cameraImg: capturedImage,
                              )))
                    ..then((value) => _initialize())
                });
          } else {
            int _time = _maxTime;
            _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
              print('[timer] : $_time');

              if (_time < 1) {
                if (_captureType == CaptureType.Video) {
                  _stopVideoRecording().then((_) {
                    print("Stop Video Recording");

                    stopRecording();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                VideoPreview(videoPath: videoPath)))
                      ..then((value) => _initialize());
                  });
                } else if (_captureType == CaptureType.ImageSequence) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ImageSequencePreview(
                              cameraSequence: _imageSequence)))
                    ..then((value) => _initialize());
                }

                _timer.cancel();
              } else {
                _time -= 1;
              }
            });
          }
        } catch (e) {
          print(e);
        }
      },
    );
    return recordButton;
  }

  Future<String> _startVideoRecording() async {
    if (!_camera.value.isInitialized) {
      print("Please wait...");
      return null;
    }

    if (_camera.value.isRecordingVideo) {
      return null;
    }

    final Directory appDirectory = await getTemporaryDirectory();
    final String videoDirectory = '${appDirectory.path}/Videos';
    await Directory(videoDirectory).create(recursive: true);
    final String currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    final String filePath = '$videoDirectory/$currentTime.mp4';

    try {
      await _camera.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    return filePath;
  }

  Future<void> _stopVideoRecording() async {
    if (!_camera.value.isRecordingVideo) {
      return null;
    }

    try {
      await _camera.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }

  Future<String> _capture() async {
    print("START CAPTURE");

    final path = join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now()}.png',
    );

    var renderObject = previewContainer.currentContext.findRenderObject();
    print(renderObject);
    if (renderObject is RenderRepaintBoundary) {
      ui.Image image = await renderObject.toImage();

      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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

    var img1 = imglib.copyRotate(img, -90);
    return img1;

//    List<int> png = new imglib.PngEncoder(level: 0, filter: 0).encodeImage(img1);
//    List<int> jpg = imglib.encodeJpg(img1);

//    return Image.memory(jpg);
  }
}
