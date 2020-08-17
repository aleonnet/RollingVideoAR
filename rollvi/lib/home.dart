import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rollvi/capture_camera.dart';
import 'package:rollvi/face_detect.dart';
import 'package:rollvi/realtime_face_detect.dart';

import 'package:rollvi/screens/remote_object.dart';
import 'package:rollvi/screens/augmented_faces.dart';

import 'video_trimmer/video_trimmer.dart';
import 'trimmer.dart';

class HomeScreen extends StatelessWidget{

  final Trimmer _trimmer = Trimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROLLVI'),
        backgroundColor: Colors.redAccent,
      ),
      body:Container(
        child: Column(
          children: <Widget>[
            RaisedButton(
              child: Text(
                "Camera Capture",
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.blue,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => CaptureCamera())
                );
              },
            ),
            RaisedButton(
              child: Text(
                  "Camera - Face Detection",
                  style: TextStyle(color: Colors.white)
              ),
              color: Colors.blue,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => RealtimeFaceDetect())
                );
              },
            ),
            RaisedButton(
              child: Text(
                  "Image - Face Detection",
                  style: TextStyle(color: Colors.white)
              ),
              color: Colors.blue,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => FaceDetectPage())
                );
              },
            ),
            RaisedButton(
              child: Text(
                  "Remote obj",
                  style: TextStyle(color: Colors.white)
              ),
              color: Colors.red,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => RemoteObject())
                );
              },
            ),
            RaisedButton(
              child: Text(
                "AR Face",
                style: TextStyle(color: Colors.white)
              ),
              color: Colors.red,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => AugmentedFacesScreen())
                );
              },
            ),
            RaisedButton(
              child: Text(
                  "Video Trimmer",
                  style: TextStyle(color: Colors.white)
              ),
              color: Colors.blue,
              onPressed: () async {
                File file = await ImagePicker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (file != null) {
                  await _trimmer.loadVideo(videoFile: file);
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return TrimmerView(_trimmer);
                  }));
                }

              },
            )
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        )
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.videocam),
        onPressed: () => {
          print("Hello")
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}