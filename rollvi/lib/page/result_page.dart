import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_path.dart';
import 'package:rollvi/ui/rollvi_appbar.dart';
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
    super.initState();
    _initialize();
  }

  void _initialize() async {
    print("@@@@@@@@@@@@initState");
    _concatVideo(widget.firstPath, widget.secondPath).then((resultPath) {
      setState(() {
        _resultVideoPath = resultPath;
        _controller = VideoPlayerController.file(File(resultPath));
        _initializeVideoPlayerFuture = _controller.initialize();
        _controller.setLooping(true);
        _controller.play();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _concatVideo(String firstPath, String secondPath) async {
    String rawDocumentPath = await getRollviTempDir();
    String resultVideoPath = "$rawDocumentPath/rollvi_${getTimestamp()}.mp4";

    print("@ firstPath: $firstPath");
    print("@ secondPath: $secondPath");

    final String cmd =
        '-y -i $firstPath -i $secondPath -filter_complex \'[0:0][1:0]concat=n=2:v=1:a=0[out]\' -map \'[out]\' $resultVideoPath';

    await new FlutterFFmpeg().execute(cmd).then((rc) {
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
      backgroundColor: AppColor.rollviBackground,
      key: _scaffoldKey,
      appBar: RollviAppBar(context, backIcon: true),
      body: Column(
        children: [
          Container(
            color: AppColor.rollviBackground,
            padding: EdgeInsets.all(10),
            child: FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  );
                } else {
                  return Container(
                    width: _size.width - 20,
                    height: _size.width - 20,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
          Expanded(
              child: Container(
                color: AppColor.rollviBackground,
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
                        makeRollviBorder(_resultVideoPath).then((value) {
                          Clipboard.setData(new ClipboardData(text: getRollviTag()));
                          Share.shareFiles([value], subject: 'Rollvi');
                        });
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
