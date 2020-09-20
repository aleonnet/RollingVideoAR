import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_size.dart';
import 'package:rollvi/home.dart';
import 'package:rollvi/insta_downloader.dart';
import 'package:rollvi/ui/instalink_dialog.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

class SequencePreviewPage extends StatefulWidget {
  final String rollviDir;

  SequencePreviewPage({Key key, this.rollviDir}) : super(key: key);

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
    await _checkVideoPath();
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

    String cmd =
        "-y -framerate 10 -i $rawDocumentPath/frame_%d.jpg -c:v mpeg4 $_outputPath";

    await _flutterFFmpeg
        .execute(cmd)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

    return _outputPath;
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
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (BuildContext context) => HomePage()));
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
              borderRadius: BorderRadius.all(Radius.circular(10)),
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
                      child: ImageIcon(
                        AssetImage("assets/insta_logo.png"),
                      ),
                      onPressed: () async {
                        String _clipData =
                            (await Clipboard.getData('text/plain')).text;
                        final inputText = await showDialog(
                            context: context,
                            builder: (BuildContext context) => InstaLinkDialog(
                              clipData: _clipData,
                            ));

                        if (inputText != null) {
                          FlutterInsta flutterInsta = new FlutterInsta();
                          await flutterInsta.downloadReels(inputText).then((String instaLink) {
                            print(instaLink);
                          });
                        }
                      },
                    ),
                    FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.photo),
                      onPressed: () {
                        FilePicker.getFile(type: FileType.video).then((File file) async {
                          print(file);
                        });
                      },
                    ),
                    FloatingActionButton(
                      heroTag: null,
                      child: Icon(Icons.file_download),
                      onPressed: () async {
                        print("Recorded Video Path $_outputPath");
                        GallerySaver.saveVideo(_outputPath,
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
                        print("Recorded Video Path $_outputPath");
                        Share.shareFiles([_outputPath],
                            text: 'Rollvi Video');
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
