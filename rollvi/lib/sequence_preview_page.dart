import 'dart:math';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class SequencePreviewPage extends StatefulWidget {
  final List<imglib.Image> cameraSequence;

  SequencePreviewPage({Key key, this.cameraSequence})
      : super(key: key);

  @override
  State createState() => new SequencePreviewPageState();
}

class SequencePreviewPageState extends State<SequencePreviewPage>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<int> _animation;

  List<Image> _imageList;

  @override
  void initState() {
    super.initState();

    int maxImages = widget.cameraSequence.length;
    print("Max Image Sequnece : $maxImages");
    _initialize();

    _controller = new AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _animation =
        new IntTween(begin: 0, end: maxImages - 1).animate(_controller);
  }

  void _initialize() {
    _imageList = new List<Image>();
    for (var image in widget.cameraSequence) {
      _imageList.add(Image.memory(imglib.encodeJpg(image)));
    }
    print("initialize image List : ${_imageList.length}");
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
                  child: _imageList[frame],
                );
              }),
        ],
      ),
    );
  }
}
