import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

  final int _maxTime = 2;
  bool isRecording = false;
  Timer _timer;
  List<Image> _imageSequence;

  List<bool> _selectedIndex = [false, false, false];
  int _selectedFilter = 1;

  @override
  void initState() {
    super.initState();
    _imageSequence = new List<Image>();
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

//            if (isRecording == true) {
//              _imageSequence.add(_convertCameraImage(image));
//            }
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ROLLVI'),
        backgroundColor: Colors.redAccent,
      ),
      body: RepaintBoundary(
        key: previewContainer,
//        child:
//            ClipRect(
//              child: Align(
//                alignment: Alignment.center,
//                widthFactor: 1,
//                heightFactor: 1, // 0.8, 0.56
//                child: AspectRatio(
//                  aspectRatio: 9 / 15, // 9 / 15
//                  child: _camera == null
//                      ? Container(color: Colors.black)
//                      : FaceCamera(faces: _faces, camera: _camera),
//                ),
//              ),
//            ),
        child: _camera == null
            ? Container(color: Colors.black)
            : FaceCamera(faces: _faces, camera: _camera, filterIndex: _selectedFilter),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          margin: EdgeInsets.only(left: 12.0, right: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                //update the bottom app bar view each time an item is clicked
                iconSize: 27.0,
                icon: Icon(
                  Icons.home,
                  //darken the icon if it is selected or else give it a different color
                  color: (_selectedIndex[0] == true)
                      ? Colors.redAccent
                      : Colors.grey.shade400,
                ),
                onPressed: () {
                  _selectedIndex[0] = !_selectedIndex[0];
                },
              ),
              IconButton(
                iconSize: 27.0,
                icon: Icon(
                  Icons.call_made,
                  color: (_selectedIndex[1] == true)
                      ? Colors.redAccent
                      : Colors.grey.shade400,
                ),
                onPressed: () {
                  _selectedIndex[1] = !_selectedIndex[1];
                },
              ),
              //to leave space in between the bottom app bar items and below the FAB
              SizedBox(
                width: 50.0,
              ),
              IconButton(
                iconSize: 27.0,
                icon: Icon(
                  Icons.face,
                  color: (_selectedIndex[2] == true)
                      ? Colors.redAccent
                      : Colors.grey.shade400,
                ),
                onPressed: () {
                  _selectedIndex[2] = !_selectedIndex[2];
                },
              ),
              IconButton(
                iconSize: 27.0,
                icon: _getFilterIcon(_selectedFilter),
                onPressed: () {
                  _selectedFilter = (_selectedFilter > 4) ? 1 : _selectedFilter += 1;
                },
              ),
            ],
          ),
        ),
        //to add a space between the FAB and BottomAppBar
        shape: CircularNotchedRectangle(),
        //color of the BottomAppBar
        color: Colors.white,
      ),
      floatingActionButton: (isRecording == false)
          ? _getRecordButton(context)
          : FloatingActionButton(
              child: Icon(Icons.fiber_manual_record),
              backgroundColor: Colors.grey,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Icon _getFilterIcon(int index) {
    Color color = Colors.grey.shade700;
    switch(index) {
      case 1:
        return Icon(Icons.looks_one, color: color,);
      case 2:
        return Icon(Icons.looks_two, color: color,);
      case 3:
        return Icon(Icons.looks_3, color: color,);
      case 4:
        return Icon(Icons.looks_4, color: color,);
      case 5:
        return Icon(Icons.looks_5, color: color,);
      default:
        return Icon(Icons.settings, color: color,);
    }
  }

  Widget _getRecordButton(BuildContext context) {
    FloatingActionButton recordButton = FloatingActionButton(
      child: Icon(Icons.camera),
      onPressed: () async {
        try {
          isRecording = true;

          String videoPath = '';

          await _camera.stopImageStream();
          _startVideoRecording().then((String filePath) {
            if (filePath != null) {
              print("Recording Start");
              setState(() {
                videoPath = filePath;
              });
            }
          });

          int _time = _maxTime;
          _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
            print('[timer] : $_time');

            if (_time < 1) {
              _stopVideoRecording().then((_) {
                print("Stop Video Recording");

                stopRecording();

                Image capturedImage = _convertCameraImage(_savedImage);
                _capture().then((path) => {
                      imageCache.clear(),
                      print("Capture Complete : $path"),
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FacePreview(
                                  cameraImg: capturedImage,
                                  cameraSequence: _imageSequence,
                                  imagePath: videoPath)))
                        ..then((value) => _initializeCamera())
                    });
              });
            } else {
              _time -= 1;
            }
          });
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

    // Do nothing if a recording is on progress
    if (_camera.value.isRecordingVideo) {
      return null;
    }

    final Directory appDirectory = await getApplicationDocumentsDirectory();
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
    String errorText = 'Error: ${e.code}\nError Message: ${e.description}';
    print(errorText);
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

  static Image _convertCameraImage(CameraImage image) {
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

//    List<int> png = new imglib.PngEncoder(level: 0, filter: 0).encodeImage(img1);
    List<int> jpg = imglib.encodeJpg(img1);

    return Image.memory(jpg);
  }
}
