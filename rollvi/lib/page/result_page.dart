import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rollvi/page/concat_video_page.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_path.dart';
import 'package:rollvi/const/app_size.dart';
import 'package:rollvi/insta_downloader.dart';
import 'package:rollvi/ui/instalink_dialog.dart';
import 'package:rollvi/utils.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

class ResultPage extends StatefulWidget {
  final String firstPath;
  final String secondPath;

  ResultPage({Key key, this.firstPath, this.secondPath}) : super(key: key);

  @override
  State createState() => new ResultPageState();
}

class ResultPageState extends State<ResultPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  String _resultVideoPath;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  void _initialize() async {
    _concatVideo(widget.firstPath, widget.secondPath).then((resultPath) {

      setState(() {
        _resultVideoPath = resultPath;
      });

      _controller = VideoPlayerController.file(File(resultPath));
      _initializeVideoPlayerFuture = _controller.initialize();
      _controller.setLooping(true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _concatVideo(String firstPath, String secondPath) async {
    String rawDocumentPath = await getRollviTempDir();
    String resultVideoPath = "$rawDocumentPath/rollvi_${getCurrentTime()}.mp4";

    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    String firstPath, secondPath;

    print("firstPath: $firstPath");
    print("secondPath: $secondPath");

    String cmd =
        '-y -i $firstPath -i $secondPath -filter_complex \'[0:0][1:0]concat=n=2:v=1:a=0[out]\' -map \'[out]\' $resultVideoPath';

    await _flutterFFmpeg.execute(cmd).then((rc) {
      print("FFmpeg process exited with rc $rc");
    });

    return resultVideoPath;
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
          title: Text('Result Video'),
          centerTitle: true,
          actions: [
            new IconButton(
              icon: Icon(
                Icons.home,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: Align(
                alignment: Alignment.center,
                widthFactor: 1,
                heightFactor: _size.width / _size.height,
                child: AspectRatio(
                  aspectRatio: _size.width / _size.height,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: FutureBuilder(
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
                  ),
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
                      child: Icon(Icons.file_download),
                      onPressed: () async {
                        print("Recorded Video Path $_resultVideoPath");
                        GallerySaver.saveVideo(_resultVideoPath,
                            albumName: 'Media')
                            .then((bool success) {
                          if (success) {
                            showInSnackBar("Video Saved!");
                          } else {
                            showInSnackBar("Failed to save the video");
                          }
                        });
                      },
                    ),
                    FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.share),
                      onPressed: () async {
                        print("Recorded Video Path $_resultVideoPath");
                        Clipboard.setData(new ClipboardData(text: getRollviTag()));
                        Share.shareFiles([_resultVideoPath],
                            text: "Rollvi");
                      },
                    ),
                  ],
                ),
              )
          )
        ],
      ),
    );
  }
}
