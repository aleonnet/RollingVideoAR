import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/ui/rollvi_appbar.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    initVideo();
  }

  void initVideo() async {
    _controller = VideoPlayerController.asset('assets/intro_family.mp4')
      ..initialize().then((_) {
        setState(() {});
      });
    _controller.setLooping(true);
    _controller.play();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    final _deviceRatio = _size.width / _size.height;

    MediaQueryData mediaQuery = MediaQuery.of(context);
    mediaQuery.devicePixelRatio;
    mediaQuery.size.height;
    mediaQuery.size.width;

    return Scaffold(
      appBar: RollviAppBar(context, homeIcon: false),
      backgroundColor: AppColor.rollviBackground,
      body: Column(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width,
            margin: EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: VideoPlayer(_controller),
            ),
          ),
          Expanded(
            child: FloatingActionButton(
              heroTag: null,
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/camera');
              },
            ),
          ),
        ],
      ),
    );
  }
}
