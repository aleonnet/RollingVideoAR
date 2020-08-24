import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              // Use the VideoPlayer widget to display the video.
              child: VideoPlayer(_controller),
            );
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Wrap the play or pause in a call to `setState`. This ensures the
          // correct icon is shown.
          setState(() {
            // If the video is playing, pause it.
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              // If the video is paused, play it.
              _controller.play();
            }
          });
        },
        // Display the correct icon depending on the state of the player.
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
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

    _controller = new AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _animation = new IntTween(begin: 0, end: maxImages-1).animate(_controller);

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
