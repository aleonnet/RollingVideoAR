import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

class ConcatVideoPage extends StatefulWidget {
  final String rollviDir;

  ConcatVideoPage({Key key, this.rollviDir}) : super(key: key);

  @override
  State createState() => new _ConcatVideoPageState();
}

class _ConcatVideoPageState extends State<ConcatVideoPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  String _rollviPath;

  String _preVideoPath;
  String _curVideoPath;

  bool isComplete;

  @override
  void initState() {
    isComplete = false;

    _preVideoPath =
        '/data/user/0/kr.hispace.rollvi/cache/file_picker/1599119080613.mp4';
    _curVideoPath =
        '/data/user/0/kr.hispace.rollvi/cache/file_picker/1599104468394.mp4';

    _initializePath();
    _makeVideoAndPlay();

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
      setState(() async {
        print("@@@ Make Rolling Video File - $outputPath");

        _controller = await VideoPlayerController.file(File(_rollviPath));
        _initializeVideoPlayerFuture = _controller.initialize();
        _controller.setLooping(true);
        _controller.play();
      });
    });
  }

  Future<String> _concatVideo() async {
    String rawDocumentPath = widget.rollviDir;
    _rollviPath = "$rawDocumentPath/rollvi.mp4";

    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    String cmd =
        '-y -i $_preVideoPath -i $_curVideoPath -filter_complex \'[0:0][1:0]concat=n=2:v=1:a=0[out]\' -map \'[out]\' $_rollviPath';

    await _flutterFFmpeg.execute(cmd).then((rc) {
      print("FFmpeg process exited with rc $rc");
      if (rc == 0) {
        setState(() {
          isComplete = true;
        });
      }
    });

    return _rollviPath;
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey =
        new GlobalKey<ScaffoldState>();

    void showInSnackBar(String value) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(
          content: new Text(value),
          action: SnackBarAction(
            label: 'OK',
            onPressed: _scaffoldKey.currentState.hideCurrentSnackBar,
          )));
    }

    return Scaffold(
      key: _scaffoldKey,
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
              (isComplete == true)
                  ? FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.share),
                      onPressed: () async {
                        print("Shaer Video: $_rollviPath");
                        Share.shareFiles([_rollviPath], text: 'Rollvi Video');
                      },
                    )
                  : Container(),
              SizedBox(height: 10),
              (isComplete == true)
                  ? FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.file_download),
                      onPressed: () async {
                        print("Save Video to Gallery: $_rollviPath");
                        GallerySaver.saveVideo(_rollviPath, albumName: 'Media')
                            .then((bool success) {
                          if (success) {
                            showInSnackBar("Video Saved!");
                            print("Video Saved!");
                          } else {
                            showInSnackBar("Failed to save the video");
                            print("Video Save Failed");
                          }
                        });
                      },
                    )
                  : Container(),
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
