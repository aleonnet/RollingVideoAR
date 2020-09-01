import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImagePreviewPage extends StatefulWidget {
  final imglib.Image cameraImg;
  final String imagePath;

  ImagePreviewPage({Key key, this.cameraImg, this.imagePath}) : super(key: key);

  @override
  State createState() => new ImagePreviewPageState();
}

class ImagePreviewPageState extends State<ImagePreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(pi),
              child: (widget.cameraImg != null)
                  ? Image.memory(imglib.encodeJpg(widget.cameraImg))
                  : new Container(),
              ),
//          Image.file(File(widget.imagePath)),
          (widget.imagePath != null)
              ? Image.file(File(widget.imagePath))
              : new Container(),
        ],
      ),
    );
  }
}
