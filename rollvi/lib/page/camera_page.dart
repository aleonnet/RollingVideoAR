import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_path.dart';
import 'package:rollvi/const/app_size.dart';
import 'package:rollvi/page/image_preview_page.dart';
import 'package:rollvi/page/making_video_page.dart';
import 'package:rollvi/ui/progress_painter.dart';
import 'package:rollvi/page/video_preview_page.dart';
import 'package:rollvi/ui/rollvi_appbar.dart';
import 'package:sprintf/sprintf.dart';

import 'package:rollvi/ui/rollvi_camera.dart';
import 'package:rollvi/utils.dart';

enum CaptureType {
  Image,
  Video,
  CameraSequence,
  ImageSequence,
}

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  final GlobalKey previewContainer = new GlobalKey();
  final GlobalKey hiddenContainer = new GlobalKey();
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

  final int _maxTime = 3;
  bool isRecording = false;
  int _frameNum = 0;
  Timer _timer;
  CameraImage _lastImage;
  List<imglib.Image> _cameraSequence;

  CaptureType _captureType = CaptureType.ImageSequence;
  int _selectedFilter = 1;
  bool _showFaceContour = false;

  String _rollviDir;

  List<imglib.Image> _hiddenCameraImgs;
  List<Uint8List> _hiddenImageBytes;
  int _hiddenFrame = 0;

  String guideText = '';

  @override
  void initState() {
    super.initState();
    _cameraSequence = new List<imglib.Image>();
    _hiddenCameraImgs = new List<imglib.Image>();
    _hiddenImageBytes = new List<Uint8List>();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _maxTime),
    );

    _initializePath();
    _initialize();
    _initializeCamera();
  }

  @override
  void dispose() async {
    super.dispose();
    _stopRecording();
    _cameraSequence.clear();
    _hiddenCameraImgs.clear();
    _hiddenImageBytes.clear();
    await _camera.stopImageStream();
    await _camera.dispose();
  }

  void _initializePath() async {
    _rollviDir = await getRollviTempDir();
    createRollviTempDir();
  }

  void _initialize() async {
    isRecording = false;
    _frameNum = 0;
    _hiddenFrame = 0;

    updateGuideText();

    if (_timer != null) _timer.cancel();
    if (_cameraSequence.isNotEmpty) _cameraSequence.clear();
    if (_hiddenCameraImgs.isNotEmpty) _hiddenCameraImgs.clear();
    if (_hiddenImageBytes.isNotEmpty) _hiddenImageBytes.clear();
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

            if (_captureType == CaptureType.CameraSequence &&
                isRecording == true) {
              _cameraSequence.add(convertCameraImage(image));

              print("Frame Num: $_frameNum");
              _frameNum += 1;
            } else if (_captureType == CaptureType.ImageSequence &&
                isRecording == true) {
              _hiddenCameraImgs.add(convertCameraImage(_lastImage));
              _captureFilter().then((value) {
                _hiddenImageBytes.add(value);
              });
            }
          });

          _isDetecting = false;
        },
      ).catchError((_) {
        _isDetecting = false;
      });
    });
  }

  void _saveCameraImage(CameraImage image) {
    imglib.Image img = convertCameraImage(image);
    String filePath = sprintf("$_rollviDir/frame_%d.jpg", [_frameNum++]);
    new File(filePath)..writeAsBytes(imglib.encodeJpg(img));
  }

  Future<String> _saveImageToFile() async {
    for (int i = 0; i < _frameNum; i++) {
      String filePath = sprintf("$_rollviDir/frame_%d.jpg", [i]);
      new File(filePath)..writeAsBytes(imglib.encodeJpg(_cameraSequence[i]));
      print("Saved File: $filePath / $_frameNum");
    }
    return _rollviDir;
  }

  _detectFaces(CameraImage cameraImage, ImageRotation rotation) async {
    final image = FirebaseVisionImage.fromBytes(
      concatenatePlanes(cameraImage.planes),
      buildMetaData(cameraImage, rotation),
    );

    List<Face> faces = await faceDetector.processImage(image);
    return faces;
  }

  void updateGuideText() {
    switch (_selectedFilter) {
      case 1:
      case 2:
      case 3:
        guideText = '가까이 와서 입을 벌려보세요';
        break;
      case 4:
        guideText = "입을 벌려보세요";
        break;
      case 5:
      case 6:
      case 7:
      case 8:
        guideText = "귀를 보여주거나 입을 벌려보세요";
        break;
      default:
        guideText = '';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    final _deviceRatio = _size.width / _size.height;

    return Scaffold(
      backgroundColor: AppColor.rollviBackground,
      appBar: RollviAppBar(context),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                child: RepaintBoundary(
                  key: previewContainer,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    child: (_camera != null)
                        ? Align(
                            alignment: Alignment.center,
                            widthFactor: 1,
                            heightFactor:
                                _camera.value.aspectRatio, // 0.8, 0.56
                            child: AspectRatio(
                              aspectRatio: _camera.value.aspectRatio, // 9 / 15
                              child: RollviCamera(
                                  faces: _faces,
                                  camera: _camera,
                                  showFaceContour: _showFaceContour,
                                  filterIndex: _selectedFilter),
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.all(10),
                            width: _size.width - 20,
                            height: _size.width - 20,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 40,
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.rollviBackgroundPoint,
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),
            child: Text(
              guideText,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 10, left: 10, right: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                color: AppColor.rollviBackgroundPoint,
              ),
              child: (_animationController.isAnimating)
                  ? Container(
                      child: Text(
                        "촬영 중이에요",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: 8,
                      gridDelegate:
                          new SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5),
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          margin: EdgeInsets.all(10),
                          color: AppColor.grey_10,
                          child: InkResponse(
                            child: Image.asset(
                              'assets/thumbnail_0${index + 1}.png',
                            ),
                            onTap: () {
                              _selectedFilter = index + 1;
                              updateGuideText();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: (_camera != null)
          ? Container(
              alignment: Alignment.bottomCenter,
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
                                                _animationController.value ==
                                                        0.0
                                                    ? Icon(
                                                        Icons.camera,
                                                        color: Colors.redAccent,
                                                      )
                                                    : Text(
                                                        timerString,
                                                        style: TextStyle(
                                                            fontSize: 15.0,
                                                            color: Colors
                                                                .redAccent),
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
                  if (_animationController.isAnimating || isRecording == true) {
                    return;
                  }
                  else {
                    _animationController.reverse(
                        from: _animationController.value == 0.0
                            ? 1.0
                            : _animationController.value);
                  }

                  startRecording(context);

                },
              ),
            )
          : Container(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void startRecording(BuildContext context) async {
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
          } else if (_captureType == CaptureType.CameraSequence) {
            _saveImageToFile().then((value) => {
              _initialize(),
              Navigator.pushReplacementNamed(
                  context, '/preview'),
            });
          } else if (_captureType == CaptureType.ImageSequence) {
            clearRollviTempDir();
            _camera.stopImageStream();

            print(
                "_hiddenCameraImgs: ${_hiddenCameraImgs.length}");
            print(
                "_hiddenImageBytes: ${_hiddenImageBytes.length}");
            imageCache.clear();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MakingVideoPage(
                      filterImgList: _hiddenImageBytes,
                      cameraImgList: _hiddenCameraImgs,
                      aspectRatio: _camera.value.aspectRatio,
                    )))
              ..then((value) {
                setState(() {
                  _initialize();
                });
              });
          }
          _timer.cancel();
        } else {
          _time -= 1;
        }
      });
    }
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
    if (_timer != null) _timer.cancel();
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
      imgFile.writeAsBytes(pngBytes);

      print("FINISH CAPTURE ${imgFile.path}");

      return imgFile.path;
    }

    return null;
  }

  Future<Uint8List> _captureFilter() async {
    var renderObject = previewContainer.currentContext.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      ui.Image image = await renderObject.toImage();

      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      return pngBytes;
    }
  }

  Future<String> captureHiddenView() async {
    String filePath = sprintf("$_rollviDir/rollvi_%d.png", [_hiddenFrame]);

    var renderObject = hiddenContainer.currentContext.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      ui.Image image = await renderObject.toImage();

      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      File imgFile = new File(filePath);
      imgFile.writeAsBytes(pngBytes);

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
