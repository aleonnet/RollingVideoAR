import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FacePreview extends StatefulWidget {
  final imglib.Image cameraImg;
  final List<imglib.Image> cameraSequence;

//  final ui.Image stickerImg;
  final String imagePath;

  FacePreview({Key key, this.cameraImg, this.cameraSequence, this.imagePath})
      : super(key: key);

  @override
  State createState() => new PreviewState();
}


class PreviewState extends State<FacePreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: Image.memory(imglib.encodeJpg(widget.cameraImg)),
          ),
          Image.file(File(widget.imagePath)),
        ],
      ),
    );
  }
}


class ImageSequenceState extends State<FacePreview>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<int> _animation;

  @override
  void initState() {
    super.initState();

    int maxImages = widget.cameraSequence.length;

    _controller = new AnimationController(vsync: this);
    _animation = new IntTween(begin: 0, end: maxImages-1).animate(_controller);

    print("Max Image Sequnece : $maxImages");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(
        children: <Widget>[
          new AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget child) {
                int frame = _animation.value;
                print("frame : $frame");

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: Image.memory(imglib.encodeJpg(widget.cameraSequence[frame])),
                );
              }),
        ],
      ),
    );
  }
}
