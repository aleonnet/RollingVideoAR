import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'face_painter.dart';

import 'utils.dart';

class RealtimeFaceDetect extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<RealtimeFaceDetect> {
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
      body: ClipRect(
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.fiber_manual_record),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await _camera.stopImageStream();
    await _camera.dispose();
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
            new Positioned.fill(
              left: (faces == null)
                  ? 0
                  : _scalePoint(
                          offset: faces[0]
                              .getContour(FaceContourType.upperLipBottom)
                              .positionsList[4],
                          imageSize: Size(camera.value.previewSize.height,
                              camera.value.previewSize.width),
                          widgetSize: Size(411.4, 685.7),
                          cameraLensDirection: CameraLensDirection.front)
                      .dx,
              top: (faces == null)
                  ? 0
                  : _scalePoint(
                          offset: faces[0]
                              .getContour(FaceContourType.upperLipBottom)
                              .positionsList[4],
                          imageSize: Size(camera.value.previewSize.height,
                              camera.value.previewSize.width),
                          widgetSize: Size(411.4, 685.7),
                          cameraLensDirection: CameraLensDirection.front)
                      .dy,
              child: Container(
//                color: Colors.black,
                child: new Image(image: new AssetImage("assets/water.gif"), alignment: Alignment.topLeft,),
              )
            )
          ],
        ));
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
