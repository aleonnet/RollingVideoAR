import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';


class ConcatRollviPage extends StatefulWidget {
  final String rollviDir;

  ConcatRollviPage({Key key, this.rollviDir})
      : super(key: key);

  @override
  State createState() => new _ConcatRollviPageState();
}

class _ConcatRollviPageState extends State<ConcatRollviPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  String _rollviPath;

  String _preVideoPath;
  String _curVideoPath;

  @override
  void initState() {
    _preVideoPath = '/data/user/0/kr.hispace.rollvi/cache/file_picker/1599119080613.mp4';
    _curVideoPath = '/data/user/0/kr.hispace.rollvi/cache/file_picker/1599104468394.mp4';
    _initializePath();
    super.initState();
  }

  void _initializePath() async {
    Directory(widget.rollviDir).createSync(recursive: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _makeVideoAndPlay() async {
    await _concatVideo().then((outputPath) {
      setState(() {
        print("@@@ Make Rolling Video File - $outputPath");
      });
    });

    _controller = await VideoPlayerController.file(File(_rollviPath));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
  }

  Future<String> _concatVideo() async {
    String rawDocumentPath = widget.rollviDir;
    _rollviPath = "$rawDocumentPath/rollvi.mp4";

    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    String cmd = '-y -i $_preVideoPath -i $_curVideoPath -filter_complex \'[0:0][1:0]concat=n=2:v=1:a=0[out]\' -map \'[out]\' $_rollviPath';

    await _flutterFFmpeg
        .execute(cmd)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

    return _rollviPath;
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
                child: Icon(Icons.image),
                onPressed: () async {
                  File file = await FilePicker.getFile(type: FileType.video);
                  print(file.path);
                  setState(() {
                      _controller = VideoPlayerController.file(file);
                      _initializeVideoPlayerFuture = _controller.initialize();
                      _controller.setLooping(true);
                      _controller.play();
                    });
                },
              ),
              SizedBox(height: 10,),
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
