import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class MakeVideoPage extends StatefulWidget {
  MakeVideoPage({Key key}) : super(key: key);

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

  String _outputPath;

  @override
  void initState() {
    // default videoPlayerController
//    _controller = VideoPlayerController.network(
//      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
//    );
//    _initializeVideoPlayerFuture = _controller.initialize();
//
    _initialize();

    super.initState();
  }

  void _initialize() async {
    await getImagesDirectory();
    await prepareAssetsPath();

    _checkVideoPath();
    _makeVideoAndPlay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVideoPath() async {
    String rawDocumentPath = (await getTemporaryDirectory()).path;
    _outputPath = '$rawDocumentPath/output.mp4';
    File outputFile = File(_outputPath);
    bool fileExist = await outputFile.exists();

    print("$_outputPath : $fileExist");

    if (fileExist) {
      await outputFile.delete(recursive: true);
      print("Removed $_outputPath");
    }
  }

  void _makeVideoAndPlay() async {
    await _executeCmd().then((outputPath) {
      setState(() {
        _outputPath = outputPath;
        print("@@@ Make Video File from images - $outputPath");
      });
    });

    _controller = await VideoPlayerController.file(File(_outputPath));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: null,
                child: Icon(Icons.movie_creation),
                onPressed: () async {
                  _makeVideoAndPlay();
                },
              ),
              SizedBox(height: 10),
              (_controller != null)
                  ? FloatingActionButton(
                      heroTag: null,
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      // Display the correct icon depending on the state of the player.
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    )
                  : Container(),
            ],
          )
        ],
      ),
    );
  }

  Future<String> _executeCmd() async {
    final appDir = await getTemporaryDirectory();
    String rawDocumentPath = appDir.path;
    final outputPath = '$rawDocumentPath/output.mp4';
    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

//    String cmd = "-r 1/5 -start_number 1 -i ${tempDirectory.path}/test%d.jpg -c:v mpeg4 -pix_fmt yuv420p $outputPath";
    String cmd =
        "-y -framerate 25 -i ${tempDirectory.path}/test%d.jpg $outputPath";

    await _flutterFFmpeg
        .execute(cmd)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

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

  prepareAssetsPath() async {
    await copyFileAssets('assets/test1.jpg', 'test1.jpg')
        .then((path) => print('Loaded asset $path.'));
    await copyFileAssets('assets/test2.jpg', 'test2.jpg')
        .then((path) => print('Loaded asset $path.'));
    await copyFileAssets('assets/test3.jpg', 'test3.jpg')
        .then((path) => print('Loaded asset $path.'));
    await copyFileAssets('assets/test4.jpg', 'test4.jpg')
        .then((path) => print('Loaded asset $path.'));
    await copyFileAssets('assets/test5.jpg', 'test5.jpg')
        .then((path) => print('Loaded asset $path.'));
  }

  void _videoMerger() async {
    final appDir = await getApplicationDocumentsDirectory();
    String rawDocumentPath = appDir.path;
    final outputPath = '$rawDocumentPath/output.mp4';

    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    String commandToExecute =
        '-y -i ${_storedVideoOne.path} -i ${_storedVideoTwo.path} -filter_complex \'[0:0][1:0]concat=n=2:v=1:a=0[out]\' -map \'[out]\' $outputPath';
    _flutterFFmpeg
        .execute(commandToExecute)
        .then((rc) => print("FFmpeg process exited with rc $rc"));
  }
}
