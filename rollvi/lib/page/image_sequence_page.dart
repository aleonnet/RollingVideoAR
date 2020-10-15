import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rollvi/const/app_path.dart';
import 'package:sprintf/sprintf.dart';

class ImageSequencePage extends StatefulWidget {
  final List<Uint8List> filterImgList;
  final List<imglib.Image> cameraImgList;
  final double aspectRatio;

  ImageSequencePage({Key key, this.filterImgList, this.cameraImgList, this.aspectRatio}) : super(key: key);

  @override
  State createState() => new ImageSequencePageState();
}

class ImageSequencePageState extends State<ImageSequencePage>
    with SingleTickerProviderStateMixin {

  final GlobalKey captureContainer = new GlobalKey();

  Timer _timer;
  int _time = 0;

  int _maxFilter;
  int _maxCamera;

  String _rollviDir;

  @override
  void initState() {
    super.initState();

    init();

    if (_timer != null) _timer.cancel();

    imageCache.clear();
    _maxCamera = widget.cameraImgList.length;
    _maxFilter = widget.filterImgList.length;

    print("@ _maxCameraImg: $_maxFilter");
    print("@ _maxCameraSequence : $_maxCamera");
  }

  void init() async {
    _rollviDir = await getRollviTempDir();
//    clearRollviTempDir();
    createRollviTempDir();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container(
        padding: EdgeInsets.all(10),
        child: RepaintBoundary(
            key: captureContainer,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  heightFactor: widget.aspectRatio,
                  child: Stack(
                    children: <Widget>[
                      (_time < _maxCamera) ?
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child: Image.memory(imglib.encodeJpg(widget.cameraImgList[_time])),
                      ) : Container(),
                    ],
                  ),
                ),
              ),
              (_time < _maxFilter) ? Image.memory(widget.filterImgList[_time]) : Container(),
            ],
          )
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          startTimer(_maxCamera);
        },
      ),
    );
  }

  void startTimer(int maxTime) {
    _time = 0;
    _timer = new Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (_time >= maxTime+1) {
        _timer.cancel();
        Navigator.pushReplacementNamed(context, '/preview');
      } else {
        print("@ time : $_time");
        if (mounted) {
          _imageCapture(_time).then((value) {
            print("saveImage: $value");
            setState(() {
              _time += 1;
            });
          });

        }
      }
    });
  }

  Future<String> _imageCapture(int index) async {
    String filePath = sprintf("$_rollviDir/rollvi_%d.png", [index]);

    var renderObject = captureContainer.currentContext.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      ui.Image image = await renderObject.toImage();

      ByteData byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      File imgFile = new File(filePath);
      imgFile.writeAsBytes(pngBytes);

      return imgFile.path;
    }

    return null;
  }
}
