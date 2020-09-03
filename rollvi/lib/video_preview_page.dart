import 'dart:io';
import 'dart:math';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewPage extends StatefulWidget {
  final String videoPath;

  VideoPreviewPage({Key key, this.videoPath})
      : super(key: key);

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
//    _controller = VideoPlayerController.network(
//      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
//    );
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

    void showInSnackBar(String value) {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(
              content: new Text(value),
              action: SnackBarAction(
                label: 'OK',
                onPressed: _scaffoldKey.currentState.hideCurrentSnackBar,
              )));
    }

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('ROLLVI'),
          backgroundColor: Colors.redAccent,
        ),
        body: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
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
                    onPressed: () async {
                      final path = join(
                        (await getExternalStorageDirectory()).path,
                        '${DateTime.now()}.mp4',
                      );

                      print("Recorded Video Path ${widget.videoPath}");
                      GallerySaver.saveVideo(widget.videoPath, albumName: 'Media').then((bool success) {
                        if (success) {
                          showInSnackBar("Video Saved!");
                          print("Video Saved!");
                        } else {
                          showInSnackBar("Failed to save the video");
                          print("Video Save Failed");
                        }
                      });
                    },
                    child: Icon(Icons.input)),
                SizedBox(height: 10),
                FloatingActionButton(
                    heroTag: null,
                    onPressed: () async {
                      print("Recorded Video Path ${widget.videoPath}");
                      Share.shareFiles([widget.videoPath], text: 'Rollvi Video');
                    },
                    child: Icon(Icons.share)),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  // Display the correct icon depending on the state of the player.
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
              ],
            )
          ],
        ));
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

