import 'dart:io';
import 'dart:math';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';


class SequencePreviewPage extends StatefulWidget {
  final String rollviDir;

  SequencePreviewPage({Key key, this.rollviDir})
      : super(key: key);

  @override
  State createState() => new SequencePreviewPageState();
}

class SequencePreviewPageState extends State<SequencePreviewPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  String _outputPath;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  void _initialize() async {
//    await _checkVideoPath();
    _outputPath = '${widget.rollviDir}/output.mp4';

    bool fileExist = await File(_outputPath).exists();
    print("fileExist : $fileExist");

    await _makeVideoAndPlay();
  }

  void _checkVideoPath() async {
    _outputPath = '${widget.rollviDir}/output.mp4';
    File outputFile = File(_outputPath);
    bool fileExist = await outputFile.exists();

    print("$_outputPath : $fileExist");

    if (fileExist) {
      await outputFile.delete(recursive: true);
      print("Removed $_outputPath");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _makeVideoAndPlay() async {
    await _executeCmd().then((outputPath) {
      setState(() {
        print("@@@ Make Video File from images - $outputPath");
      });
    });

    _controller = await VideoPlayerController.file(File(_outputPath));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
  }

  Future<String> _executeCmd() async {
    String rawDocumentPath = widget.rollviDir;

    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

//    String cmd = "-r 1/5 -start_number 1 -i ${tempDirectory.path}/test%d.jpg -c:v mpeg4 -pix_fmt yuv420p $outputPath";
    String cmd =
        "-y -framerate 5 -i $rawDocumentPath/frame_%d.jpg -c:v mpeg4 $_outputPath";

    await _flutterFFmpeg
        .execute(cmd)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

    return _outputPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      body: Stack(
//        children: [
//          Image.file(File("${widget.rollviDir}/frame_9.jpg")),
//        ],
//      ),
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
}
