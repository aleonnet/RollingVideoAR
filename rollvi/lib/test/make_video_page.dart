import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class MakeVideoPage extends StatefulWidget {
  MakeVideoPage({Key key})
      : super(key: key);

  @override
  State createState() => new MakeVideoPageState();
}

class MakeVideoPageState extends State<MakeVideoPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  File _storedVideoOne;
  File _storedVideoTwo;

  Directory tempDirectory;
  String assetPath;

  @override
  void initState() {
    getImagesDirectory();
    prepareAssetsPath();


    _executeCmd().then((outputPath) {
      _controller = VideoPlayerController.file(File(outputPath));
      _initializeVideoPlayerFuture = _controller.initialize();

      _controller.setLooping(true);
    });

//    _controller = VideoPlayerController.network(
//      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
//    );

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

    return Scaffold(
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: () {
//          setState(() {
//            _controller.value.isPlaying ? _controller.pause() : _controller.play();
//          });
//        },
//        child: Icon(
//          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//        ),
//      ),
    );
  }

  Future<String> _executeCmd() async {
    final appDir = await getTemporaryDirectory();
    String rawDocumentPath = appDir.path;
    final outputPath = '$rawDocumentPath/output.mp4';
    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();


    print(outputPath);
//    String cmd = "-r 60 -f assets -s 350x300 -i say_h%02d.webp -vcode libx264 -crf 25 -pix_fmt yuv420p $outputPath";
    String cmd = "-r 1/5 -start_number 1 -i ${tempDirectory.path}/test%d.jpg -c:v libx264 -pix_fmt yuv420p $outputPath";

    _flutterFFmpeg.execute(cmd).then((rc) => print("FFmpeg process exited with rc $rc"));

    return outputPath;
  }


  getImagesDirectory() async {
    tempDirectory = await getTemporaryDirectory();
    print(tempDirectory.path);
  }

  getImagePath(String assetName) {
    return join(tempDirectory.path, assetName);
  }

  Future<File> copyFileAssets(String assetName, String localName) async {
    final ByteData assetByteData = await rootBundle.load(assetName);

    final List<int> byteList = assetByteData.buffer
        .asUint8List(assetByteData.offsetInBytes, assetByteData.lengthInBytes);

    final String fullTemporaryPath = join(tempDirectory.path, localName);

    return File(fullTemporaryPath)
        .writeAsBytes(byteList, mode: FileMode.writeOnly, flush: true);
  }

  prepareAssetsPath() {
    copyFileAssets('assets/test1.jpg', 'test1.jpg')
        .then((path) => print('Loaded asset $path.'));
    copyFileAssets('assets/test2.jpg', 'test2.jpg')
        .then((path) => print('Loaded asset $path.'));
    copyFileAssets('assets/test3.jpg', 'test3.jpg')
        .then((path) => print('Loaded asset $path.'));
    copyFileAssets('assets/test4.jpg', 'test4.jpg')
        .then((path) => print('Loaded asset $path.'));
    copyFileAssets('assets/test5.jpg', 'test5.jpg')
        .then((path) => print('Loaded asset $path.'));
  }


  void _videoMerger() async {
    final appDir = await getApplicationDocumentsDirectory();
    String rawDocumentPath = appDir.path;
    final outputPath = '$rawDocumentPath/output.mp4';

    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    String commandToExecute = '-y -i ${_storedVideoOne.path} -i ${_storedVideoTwo.path} -filter_complex \'[0:0][1:0]concat=n=2:v=1:a=0[out]\' -map \'[out]\' $outputPath';
    _flutterFFmpeg.execute(commandToExecute).then((rc) => print("FFmpeg process exited with rc $rc"));
  }
}
