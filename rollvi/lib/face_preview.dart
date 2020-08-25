import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class FacePreview extends StatefulWidget {
  final Image cameraImg;
  final List<Image> cameraSequence;

//  final ui.Image stickerImg;
  final String imagePath;

  FacePreview({Key key, this.cameraImg, this.cameraSequence, this.imagePath})
      : super(key: key);

  @override
  State createState() => new VideoState();
}

class VideoState extends State<FacePreview> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    print("video path : ${widget.imagePath}");
    _controller = VideoPlayerController.file(File(widget.imagePath));
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
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('ROLLVI'),
          backgroundColor: Colors.redAccent,
        ),
        body: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the VideoPlayerController has finished initialization, use
              // the data it provides to limit the aspect ratio of the video.
//            return ClipRect(
//              child: Align(
//                alignment: Alignment.center,
//                widthFactor: 1.0,
//                heightFactor: 0.88, // 0.8, 0.56
//                child: AspectRatio(
//                  aspectRatio: 9 / 15, // 9 / 15
//                  child: Transform(
//                    alignment: Alignment.center,
//                    transform: Matrix4.rotationY(pi),
//                    child: VideoPlayer(_controller),
//                  ),
//                ),
//              ),
//            );
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: VideoPlayer(_controller),
              );
            } else {
              // If the VideoPlayerController is still initializing, show a
              // loading spinner.
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

                      print("Recorded Video Path $widget.imagePath");
                      GallerySaver.saveVideo(widget.imagePath, albumName: 'Media').then((bool success) {
                        if (success) {
                          print("Video Saved!");
                        } else {
                          print("Video Save Failed");
                        }
                      });
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

class PreviewState extends State<FacePreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: widget.cameraImg,
          ),
          Image.file(File(widget.imagePath)),
        ],
      ),
    );
  }
}

class ImageSequenceState extends State<FacePreview>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<int> _animation;

  @override
  void initState() {
    super.initState();

    int maxImages = widget.cameraSequence.length;

    _controller = new AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _animation =
        new IntTween(begin: 0, end: maxImages - 1).animate(_controller);

    print("Max Image Sequnece : $maxImages");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(
        children: <Widget>[
          new AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget child) {
                int frame = _animation.value;
                print("frame : $frame");

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: widget.cameraSequence[frame],
                );
              }),
        ],
      ),
    );
  }
}
