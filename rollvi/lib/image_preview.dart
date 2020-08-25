import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';


class ImagePreview extends StatefulWidget {
  final imglib.Image cameraImg;

  ImagePreview({Key key, this.cameraImg})
      : super(key: key);

  @override
  State createState() => new ImagePreviewState();
}

class ImagePreviewState extends State<ImagePreview> {
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
//          Image.file(File(widget.imagePath)),
        ],
      ),
    );
  }
}
