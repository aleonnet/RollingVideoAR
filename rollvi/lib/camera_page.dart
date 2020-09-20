import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_size.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'package:rollvi/image_preview_page.dart';
import 'package:rollvi/sequence_preview_page.dart';
import 'package:rollvi/ui/progress_painter.dart';
import 'package:rollvi/video_preview_page.dart';
import 'package:sprintf/sprintf.dart';

import 'home.dart';
import 'home.dart';
import 'ui/rollvi_camera.dart';
import 'utils.dart';
import 'utils.dart';

enum CaptureType {
  Image,
  Video,
  ImageSequence,
}

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  final GlobalKey previewContainer = new GlobalKey();
  AnimationController _animationController;

  final FaceDetector faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
          enableClassification: false,
          enableLandmarks: false,
          enableContours: true,
          enableTracking: false));

  List<Face> _faces;
  CameraController _camera;
  bool _isDetecting = false;

  final int _maxTime = 5;
  bool isRecording = false;
  int _frameNum = 0;
  Timer _timer;
  CameraImage _lastImage;
  List<imglib.Image> _imageSequence;

  CaptureType _captureType = CaptureType.ImageSequence;
  int _selectedFilter = 1;
  bool _showFaceContour = false;

  String _rollviDir;

  @override
  void initState() {
    super.initState();
    _imageSequence = new List<imglib.Image>();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );

    _initializePath();
    _initialize();
  }

  @override
  void dispose() async {
    super.dispose();
    _stopRecording();
//    Directory(_rollviDir).deleteSync(recursive: true);
    await _camera.stopImageStream();
    await _camera.dispose();
  }

  void _initializePath() async {
    final rawDir = (await getTemporaryDirectory()).path;
    _rollviDir = '$rawDir/rollvi';

    Directory(_rollviDir).createSync(recursive: true);
  }

  void _initialize() async {
    isRecording = false;
    _frameNum = 0;

    if (_timer != null) _timer.cancel();
    if (_imageSequence.isNotEmpty) _imageSequence.clear();

    _initializeCamera();

    await getExternalStorageDirectory();
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
              _imageSequence.add(convertCameraImage(image));

              print("Frame Num: $_frameNum");
              _frameNum += 1;

//              _saveCameraImage(image).then((filePath) {
////                print("File is writed : $filePath");
//              });
            }
          });

          _isDetecting = false;
        },
      ).catchError((_) {
        _isDetecting = false;
      });
    });
  }

  Future<void> _saveCameraImage(CameraImage image) async {
    imglib.Image img = convertCameraImage(image);
    String filePath = sprintf("$_rollviDir/frame_%d.jpg", [_frameNum++]);
    new File(filePath)..writeAsBytes(imglib.encodeJpg(img));
  }

  Future _saveImageToFile() async {
    for (int i = 0; i < _frameNum; i++) {
      String filePath = sprintf("$_rollviDir/frame_%d.jpg", [i]);
      new File(filePath)..writeAsBytes(imglib.encodeJpg(_imageSequence[i]));
      print("Saved File: $filePath / $_frameNum");
    }
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
    final _size = MediaQuery.of(context).size;
    final _deviceRatio = _size.width / _size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(AppSize.AppBarHeight),
        child: AppBar(
          title: Text('ROLLVI'),
          centerTitle: true,
          actions: [
            new IconButton(
              icon: Icon(
                Icons.home,
                color: Colors.white,
              ),
              onPressed: () {
//                print("size : $_size");
//                print("deviceRation: $_deviceRatio");
//                print("_camera: ${_camera.value.aspectRatio}");

                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: RepaintBoundary(
              key: previewContainer,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child:  (_camera != null) ? Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  heightFactor: _camera.value.aspectRatio, // 0.8, 0.56
                  child: _camera == null
                      ? Container(
                    color: Colors.black,
                  )
                      : AspectRatio(
                    aspectRatio: _camera.value.aspectRatio, // 9 / 15
                    child: RollviCamera(
                        faces: _faces,
                        camera: _camera,
                        showFaceContour: _showFaceContour,
                        filterIndex: _selectedFilter),
                  ),
                ) : Container(),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
//                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: AppColor.nearlyWhite,
              ),
              child: (_animationController.isAnimating)
                  ? Container()
                  : GridView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: 5,
                      gridDelegate:
                          new SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5),
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          margin: EdgeInsets.all(10),
                          color: AppColor.grey_10,
                          child: InkResponse(
                            child: Image.asset(
                              'assets/say_m0${index + 1}.webp',
                              color: Colors.redAccent,
                            ),
                            onTap: () {
                              _selectedFilter = index + 1;
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: (_camera != null) ? Container(
        padding: EdgeInsets.only(
            top:
                _size.width * _camera.value.aspectRatio),
        alignment: Alignment.center,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Align(
                              alignment: FractionalOffset.center,
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Stack(
                                  children: <Widget>[
                                    Positioned.fill(
                                      child: CustomPaint(
                                          painter: ProgressTimerPainter(
                                        animation: _animationController,
                                        backgroundColor: Colors.white,
                                        color: Colors.redAccent,
                                      )),
                                    ),
                                    Align(
                                      alignment: FractionalOffset.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          _animationController.value == 0.0
                                              ? Icon(
                                                  Icons.camera,
                                                  color: Colors.redAccent,
                                                )
                                              : Text(
                                                  timerString,
                                                  style: TextStyle(
                                                      fontSize: 15.0,
                                                      color: Colors.redAccent),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
          onPressed: () async {
            if (_animationController.isAnimating)
              _animationController.stop();
            else {
              _animationController.reverse(
                  from: _animationController.value == 0.0
                      ? 1.0
                      : _animationController.value);
            }

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
              imglib.Image capturedImage = convertCameraImage(_lastImage);
              _imageCapture().then((path) => {
                imageCache.clear(),
                print("Capture Complete : $path"),
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ImagePreviewPage(
                          cameraImg: capturedImage,
                          imagePath: path,
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

                      _stopRecording();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  VideoPreviewPage(videoPath: videoPath)))
                        ..then((value) => _initialize());
                    });
                  } else if (_captureType == CaptureType.ImageSequence) {
                    print("Caputre Over!!!!!!");

                    _saveImageToFile().then((value) => {
                      _initialize(),
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SequencePreviewPage(
                                rollviDir: _rollviDir,
                              )))
                    });
                  }
                  _timer.cancel();
                } else {
                  _time -= 1;
                }
              });
            }
          },
        ),
      ) : Container(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
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

  void _stopRecording() {
    isRecording = false;
    _timer.cancel();
  }

  void _showCameraException(CameraException e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }

  Future<String> _imageCapture() async {
    print("START CAPTURE");

    final path = join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now()}.png',
    );

    var renderObject = previewContainer.currentContext.findRenderObject();
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

  String get timerString {
    Duration duration =
        _animationController.duration * _animationController.value;
//    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    return (duration.inSeconds % 60).toString();
  }
}
