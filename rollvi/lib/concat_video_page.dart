import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_size.dart';
import 'package:rollvi/home.dart';
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

  VideoPlayerController _capturedVideoController;
  VideoPlayerController _gottenVideoController;

  VideoPlayerController _curVideoController;

  String _rollviPath;

  String _capturedVideoPath;
  String _gottenVideoPath;

  bool isComplete;

  bool reverse;

  @override
  void initState() {
    isComplete = false;
    reverse = false;

    _initializePath();

    _capturedVideoController = VideoPlayerController.network('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
    _capturedVideoController.initialize();
    _capturedVideoController.setLooping(true);

    _gottenVideoController = VideoPlayerController.network('https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4');
    _gottenVideoController.initialize();
    _gottenVideoController.setLooping(true);

//    _preVideoPath =
//        '/data/user/0/kr.hispace.rollvi/cache/file_picker/1599119080613.mp4';
//    _curVideoPath =
//        '/data/user/0/kr.hispace.rollvi/cache/file_picker/1599104468394.mp4';
//

//    _makeVideoAndPlay();

    super.initState();
  }

  void _initializePath() async {
    Directory(widget.rollviDir).createSync(recursive: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _capturedVideoController.dispose();
    _gottenVideoController.dispose();
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

  Future<String> _concatVideo([bool reverse=false]) async {
    String rawDocumentPath = widget.rollviDir;
    _rollviPath = "$rawDocumentPath/rollvi.mp4";

    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    String firstVideoPath = _gottenVideoPath;
    String secondVideoPath = _capturedVideoPath;

    if (reverse) {
     firstVideoPath = _capturedVideoPath;
     secondVideoPath = _gottenVideoPath;
    }

    String cmd =
        '-y -i $firstVideoPath -i $secondVideoPath -filter_complex \'[0:0][1:0]concat=n=2:v=1:a=0[out]\' -map \'[out]\' $_rollviPath';

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
    final _size = MediaQuery.of(context).size;

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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(AppSize.AppBarHeight),
        child: AppBar(
          title: Text('ROLLVI'),
          centerTitle: true,
          actions: [
            new IconButton(
              icon: Icon(
                Icons.home,
                color: Colors.white,
              ),
              onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => HomePage()));
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              widthFactor: 1,
              heightFactor: _size.width / _size.height,
              child: AspectRatio(
                aspectRatio: _size.width / _size.height,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: (_curVideoController != null) ? VideoPlayer(_curVideoController) : Container(),
                ),
              ),
            ),
          ),
          Expanded(
              child: Container(
                color: AppColor.nearlyWhite,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.queue_play_next),
                      backgroundColor: Colors.blueAccent,
                      onPressed: () {
                        setState(() {
                          _curVideoController = (!reverse) ? _capturedVideoController : _gottenVideoController;
                          _curVideoController.play();

                          reverse = !reverse;
                        });
                      },
                    ),

                    FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.undo),
                      onPressed: () {

                      },
                    ),

                    FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.repeat),
                      onPressed: () {

                      },
                    ),

                    FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.check),
                      onPressed: () {

                      },
                    ),
                  ],
                ),
              )
          )
        ],
      ),

//      body: FutureBuilder(
//        future: _initializeVideoPlayerFuture,
//        builder: (context, snapshot) {
//          if (snapshot.connectionState == ConnectionState.done) {
//            return AspectRatio(
//              aspectRatio: _gottenVideoController.value.aspectRatio,
//              child: VideoPlayer(_gottenVideoController),
//            );
//          } else {
//            return Center(child: CircularProgressIndicator());
//          }
//        },
//      ),
    );
  }
}
