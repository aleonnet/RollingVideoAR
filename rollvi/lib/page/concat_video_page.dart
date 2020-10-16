import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_path.dart';
import 'package:rollvi/const/app_size.dart';
import 'package:rollvi/page/result_page.dart';
import 'package:rollvi/ui/rollvi_appbar.dart';
import 'package:rollvi/utils.dart';
import 'package:video_player/video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ConcatVideoPage extends StatefulWidget {
  final File currentFile;
  final File galleryFile;
  final String instaLink;

  ConcatVideoPage({Key key, this.currentFile, this.galleryFile, this.instaLink})
      : super(key: key);

  @override
  State createState() => new _ConcatVideoPageState();
}

class _ConcatVideoPageState extends State<ConcatVideoPage> {
  Future<void> _initializeVideoPlayerFuture1;
  Future<void> _initializeVideoPlayerFuture2;

  VideoPlayerController _capturedVideoController;
  VideoPlayerController _gottenVideoController;

  String _capturedVideoPath;
  String _gottenVideoPath;

  bool isComplete;
  bool isGalleryFile;

  bool reverse;
  int _current = 0;

  @override
  void initState() {
    isComplete = false;
    reverse = false;

    _initializePath();
    _initializeVideo();

    super.initState();
  }

  void _initializeVideo() async {
    _cropVideo(widget.currentFile.path).then((outputPath) {
      setState(() {
        _capturedVideoController = VideoPlayerController.file(File(outputPath));
        _initializeVideoPlayerFuture1 = _capturedVideoController.initialize();
        _capturedVideoController.setLooping(true);
        _capturedVideoController.play();
        _capturedVideoPath = outputPath;
        print("_capturedVideoPath: $_capturedVideoPath");
      });
    });

    if (widget.galleryFile != null) {
      isGalleryFile = true;

      _cropVideo(widget.galleryFile.path).then((outputPath) {
        setState(() {
          _gottenVideoController = VideoPlayerController.file(File(outputPath));
          _initializeVideoPlayerFuture2 = _gottenVideoController.initialize();
          _gottenVideoController.setLooping(true);
          _gottenVideoController.play();
          _gottenVideoPath = outputPath;
          print("_gottenVideoPath: $_gottenVideoPath");
        });
      });
    } else if (widget.instaLink != null) {
      isGalleryFile = false;

      _gottenVideoController = VideoPlayerController.network(widget.instaLink);
      print("@@@@@@@@@@@@${widget.instaLink}");
    }

    print("_capturedVideoPath: $_capturedVideoPath");
    print("_gottenVideoPath: $_gottenVideoPath");
  }

  void _initializePath() async {
    String rollviDir = await getRollviTempDir();
    Directory(rollviDir).createSync(recursive: true);
  }

  Future<String> _cropVideo(String filePath) async {
    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    final rawDir = await getRollviTempDir();
    final String resultPath = '$rawDir/video_${getTimestamp()}.mp4';

    String cmd = '-y -i $filePath -filter:v "crop=392:392" $resultPath';
    await _flutterFFmpeg.execute(cmd).then((rc) {
      print("FFmpeg process exited with rc $rc");
    });
    return resultPath;
  }

  @override
  void dispose() {
    _capturedVideoController.dispose();
    _gottenVideoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColor.rollviBackground,
      appBar: RollviAppBar(context, backIcon: true),
      body: Column(
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              widthFactor: 1,
              heightFactor: _size.width / _size.height,
              child: AspectRatio(
                aspectRatio: _size.width / _size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CarouselSlider(
                        options: CarouselOptions(
                            aspectRatio: 1,
                            viewportFraction: 1,
                            enableInfiniteScroll: false,
                            reverse: reverse,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;

                                if (_current == 0) {
                                  _capturedVideoController.play();
                                } else if (_current == 1) {
                                  _gottenVideoController.play();
                                }
                              });
                            }),
                        items: [
                          Container(
                              color: AppColor.rollviBackground,
                              padding: EdgeInsets.all(10),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: FutureBuilder(
                                    future: _initializeVideoPlayerFuture1,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.all(Radius.circular(20)),
                                          child: VideoPlayer(
                                              _capturedVideoController),
                                        );
                                      } else {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }
                                    },
                                  ))),
                          Container(
                              color: AppColor.rollviBackground,
                              padding: EdgeInsets.all(10),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: FutureBuilder(
                                    future: _initializeVideoPlayerFuture2,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.all(Radius.circular(20)),
                                          child: VideoPlayer(_gottenVideoController),
                                        );
                                      } else {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }
                                    },
                                  ))),
                        ]),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: AppColor.rollviBackground,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.rollviBackgroundPoint,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FlatButton(
                          child: (!reverse)
                              ? Icon(Icons.videocam,
                              color: (_current == 0)
                                  ? Colors.white
                                  : Colors.white10)
                              : Icon(Icons.panorama,
                              color: (_current == 1)
                                  ? Colors.white
                                  : Colors.white10),
                        ),
                        FlatButton(
                          child: (!reverse)
                              ? Icon(Icons.panorama,
                              color: (_current == 1)
                                  ? Colors.white
                                  : Colors.white10)
                              : Icon(Icons.videocam,
                              color: (_current == 0)
                                  ? Colors.white
                                  : Colors.white10),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: null,
                          child: Icon(Icons.repeat),
                          onPressed: () {
                            setState(() {
                              reverse = !reverse;
                            });
                          },
                        ),
                        FloatingActionButton(
                          heroTag: null,
                          child: Icon(Icons.check),
                          onPressed: () {
                            String firstPath = (!reverse)
                                ? _capturedVideoPath
                                : _gottenVideoPath;
                            String secondPath = (!reverse)
                                ? _gottenVideoPath
                                : _capturedVideoPath;

                            _capturedVideoController.pause();
                            _gottenVideoController.pause();

                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) => ResultPage(
                                      firstPath: firstPath,
                                      secondPath: secondPath,
                                    )));
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
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
