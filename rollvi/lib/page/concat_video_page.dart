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
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

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

    _capturedVideoController = VideoPlayerController.file(widget.currentFile);
    _capturedVideoController.initialize();
    _capturedVideoController.setLooping(true);
    _capturedVideoController.play();

    if (widget.galleryFile != null) {
      isGalleryFile = true;
      _gottenVideoController = VideoPlayerController.file(widget.galleryFile);
    } else if (widget.instaLink != null) {
      isGalleryFile = false;
      _gottenVideoController = VideoPlayerController.network(widget.instaLink);
      print("@@@@@@@@@@@@${widget.instaLink}");
    }

    _gottenVideoController.initialize();
    _gottenVideoController.setLooping(true);
    _gottenVideoController.play();

    super.initState();
  }

  void _initializePath() async {
    String rollviDir = await getRollviTempDir();
    Directory(rollviDir).createSync(recursive: true);

    _capturedVideoPath = widget.currentFile.path;
    if (isGalleryFile) {
      _gottenVideoPath = widget.galleryFile.path;
    }
  }

  Future<String> _cropVideo(String filePath) async {
    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    final String resultPath = 'mod_$filePath';

    String cmd = '-y -i $filePath -filter:v "crop=640:640" $resultPath';
    await _flutterFFmpeg.execute(cmd).then((rc) {
      print("FFmpeg process exited with rc $rc");
    });

    return resultPath;
  }


  @override
  void dispose() {
    _controller.dispose();
    _capturedVideoController.dispose();
    _gottenVideoController.dispose();
    clearRollviTempDir();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(AppSize.AppBarHeight),
        child: AppBar(
          title: Text('Edit Video'),
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
          leading: new IconButton(
              icon: Icon(
                Icons.keyboard_backspace,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              }),
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
                            padding: EdgeInsets.all(10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(pi),
                              child: (_capturedVideoController != null)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child:
                                          VideoPlayer(_capturedVideoController),
                                    )
                                  : Container(),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(pi),
                              child: (_gottenVideoController != null)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child:
                                          VideoPlayer(_gottenVideoController),
                                    )
                                  : Container(),
                            ),
                          ),
                        ]),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: AppColor.nearlyWhite,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FlatButton(
                        child: (!reverse)
                            ? Icon(Icons.videocam,
                                color: (_current == 0)
                                    ? Colors.black
                                    : Colors.grey)
                            : Icon(Icons.panorama,
                                color: (_current == 1)
                                    ? Colors.black
                                    : Colors.grey),
                      ),
                      FlatButton(
                        child: (!reverse)
                            ? Icon(Icons.panorama,
                                color: (_current == 1)
                                    ? Colors.black
                                    : Colors.grey)
                            : Icon(Icons.videocam,
                                color: (_current == 0)
                                    ? Colors.black
                                    : Colors.grey),
                      ),
                    ],
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
                            String firstPath = (!reverse) ? _capturedVideoPath : _gottenVideoPath;
                            String secondPath = (!reverse) ? _gottenVideoPath : _capturedVideoPath;

                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    ResultPage(firstPath: firstPath, secondPath: secondPath,)));
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
