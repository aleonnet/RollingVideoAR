import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';


class SelectVideoPage extends StatefulWidget {
  SelectVideoPage({Key key}) : super(key: key);

  @override
  _SelectVideoPageState createState() => _SelectVideoPageState();
}

class _SelectVideoPageState extends State<SelectVideoPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  File _videoFile;

  @override
  void initState() {
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
      body: Column(
        children: <Widget>[
          Visibility(
            visible: _controller != null,
            child: FutureBuilder(
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
          ),
          RaisedButton(
            child: Text("Video"),
            onPressed: () {
              _getVideoFromGallery();
            },
          ),
        ],
      ),
      floatingActionButton: _controller == null
          ? null
          : FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  Future _getVideoFromGallery() async {
    ImagePicker.pickVideo(source: ImageSource.gallery).then((file) async {
      setState(() {
        _videoFile = file;
        _controller = VideoPlayerController.file(_videoFile);

        _initializeVideoPlayerFuture = _controller.initialize();

        _controller.setLooping(true);
      });
    });
  }
}