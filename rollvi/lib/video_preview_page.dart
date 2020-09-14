import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_size.dart';
import 'package:rollvi/home.dart';
import 'package:rollvi/insta_downloader.dart';
import 'package:rollvi/ui/instalink_dialog.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewPage extends StatefulWidget {
  final String videoPath;

  VideoPreviewPage({Key key, this.videoPath}) : super(key: key);

  @override
  State createState() => new VideoPreviewPageState();
}

class VideoPreviewPageState extends State<VideoPreviewPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    print("video path : ${widget.videoPath}");
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        backgroundColor: Colors.black,
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
                  print("size: ${_size}");
//                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => HomePage()));
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
                    child: VideoPlayer(_controller),
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
                        print("Recorded Video Path ${widget.videoPath}");
                        GallerySaver.saveVideo(widget.videoPath,
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
                        print("Recorded Video Path ${widget.videoPath}");
                        Share.shareFiles([widget.videoPath],
                            text: 'Rollvi Video');
                      },
                    ),
                  ],
                ),
              )
            )
          ],
        ),


//        body: FutureBuilder(
//          future: _initializeVideoPlayerFuture,
//          builder: (context, snapshot) {
//            if (snapshot.connectionState == ConnectionState.done) {
//              return ClipRect(
//                child: Align(
//                  alignment: Alignment.center,
//                  widthFactor: 1,
//                  heightFactor: _size.width / _size.height,
//                  child: Transform(
//                    alignment: Alignment.center,
//                    transform: Matrix4.rotationY(pi),
//                    child: VideoPlayer(_controller),
//                  ),
//                ),
//              );
//            } else {
//              return Center(child: CircularProgressIndicator());
//            }
//          },
//        ),

    );
  }

  Widget _getFAB() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22),
      backgroundColor: Color(0xFF801E48),
      visible: true,
      curve: Curves.bounceIn,
      children: [
        // FAB 1
        SpeedDialChild(
            child: Icon(Icons.assignment_turned_in),
            backgroundColor: Color(0xFF801E48),
            onTap: () {
              /* do anything */
            },
            label: 'Button 1',
            labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: Color(0xFF801E48)),
        // FAB 2
        SpeedDialChild(
            child: Icon(Icons.assignment_turned_in),
            backgroundColor: Color(0xFF801E48),
            onTap: () {
              setState(() {});
            },
            label: 'Button 2',
            labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: Color(0xFF801E48))
      ],
    );
  }
}
