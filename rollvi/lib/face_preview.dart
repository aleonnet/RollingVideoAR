import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class FacePreview extends StatelessWidget{
  final imglib.Image cameraImg;
//  final ui.Image stickerImg;

  final String imagePath;

  const FacePreview({Key key, this.cameraImg, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            Image.memory(imglib.encodeJpg(cameraImg)),
            Image.file(File(imagePath)),
          ],
        ),
      )
    );
  }
}