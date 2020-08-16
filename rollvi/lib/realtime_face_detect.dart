import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rollvi/darwin_camera/darwin_camera.dart';
import 'package:rollvi/face_contour_detection/utils.dart';

import 'face_painter.dart';

class RealtimeFaceDetect extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<RealtimeFaceDetect> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;

  bool _isDetecting = false;

  ui.Image _image;

  CameraController _camera;
  CameraLensDirection _cameraDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription description = await getCamera(_cameraDirection);

    List<CameraDescription> cameraDescription = await availableCameras();

    print(cameraDescription.first);

    _camera = CameraController(
        cameraDescription[0],
         ResolutionPreset.high
    );

    await _camera.initialize();


    _camera.startImageStream((image) => {
      _detectFaces(image).then(
          (dynamic result) {
            setState(() {
              _faces = result;
            });
          }
      )
    });
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }

  _detectFaces(CameraImage cameraImage) async {
    final image = FirebaseVisionImage.fromBytes(
        concatenatePlanes(cameraImage.planes),
        FirebaseVisionImageMetadata(
          rawFormat: cameraImage.format.raw,
          size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: ImageRotation.rotation0,
          planeData: cameraImage.planes.map(
                (Plane plane) {
              return FirebaseVisionImagePlaneMetadata(
                bytesPerRow: plane.bytesPerRow,
                height: plane.height,
                width: plane.width,
              );
            },
          ).toList(),
        )
    );

    final faceDetector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: false));

    List<Face> faces = await faceDetector.processImage(image);

    if (mounted) {
      setState(() {
        _faces = faces;
      });
    }
  }

  _getImageAndDetectFaces() async {
    final imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      isLoading = true;
    });

    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: false));

    List<Face> faces = await faceDetector.processImage(image);

    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageFile);
      });
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
          (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _camera == null
          ? const Center(
        child: Text('camera is null'),
      )
          : LiveCamera(
        faces: _faces,
        camera: _camera
      )
    );
  }
  
  
  
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      body: isLoading
//          ? Center(child: CircularProgressIndicator())
//          : (_imageFile == null)
//          ? Center(child: Text('No image selected'))
//          : Center(
//        child: FittedBox(
//          child: SizedBox(
//            width: _image.width.toDouble(),
//            height: _image.height.toDouble(),
//            child: CustomPaint(
//              painter: FacePainter(_image, _faces),
//            ),
//          ),
//        ),
//      ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: _getImageAndDetectFaces,
//        tooltip: 'Pick Image',
//        child: Icon(Icons.add_a_photo),
//      ),
//    );
//  }
}

class LiveCamera extends StatelessWidget {
  final List<Face> faces;
  final CameraController camera;
  final bool cameraEnabled;

  const LiveCamera(
      {Key key, this.faces, this.camera, this.cameraEnabled = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container (
      constraints: const BoxConstraints.expand(),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          cameraEnabled ? CameraPreview(camera) : Container( color: Colors.black ),
        ],
      )
    );
  }
}
