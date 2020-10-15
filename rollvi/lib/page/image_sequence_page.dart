import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FacePreview extends StatefulWidget {
  final List<Uint8List> cameraImg;
  final List<imglib.Image> cameraSequence;


  FacePreview({Key key, this.cameraImg, this.cameraSequence}) : super(key: key);

  @override
  State createState() => new ImageSequenceState();
}

class ImageSequenceState extends State<FacePreview>
    with SingleTickerProviderStateMixin {

  Timer _timer;
  int _time = 0;

  int _maxCameraImg;
  int _maxCameraSequence;

  @override
  void initState() {
    super.initState();

    if (_timer != null) _timer.cancel();

    imageCache.clear();
    _maxCameraSequence = widget.cameraSequence.length;
    _maxCameraImg = widget.cameraImg.length;

    print("@ _maxCameraImg: $_maxCameraImg");
    print("@ _maxCameraSequence : $_maxCameraSequence");
  }

  @override
  void dispose() {
    super.dispose();
  }

  void startTimer(int maxTime) {
    _time = 0;
    _timer = new Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_time > maxTime) {
        _timer.cancel();
      } else {
        print("@ time : $_time");
        if (mounted) {
          setState(() {
            _time += 1;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(
        children: <Widget>[
          (_time < _maxCameraSequence) ?
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: Image.memory(imglib.encodeJpg(widget.cameraSequence[_time])),
          ) : Container(),
          (_time < _maxCameraImg) ? Image.memory(widget.cameraImg[_time]) : Container()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          startTimer(widget.cameraSequence.length);
        },
      ),
    );
  }
}
