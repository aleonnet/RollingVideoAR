import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rollvi/select_video_page.dart';
import 'package:rollvi/test/countdown_timer.dart';
import 'package:rollvi/test/make_video_page.dart';
import 'backup/face_detect.dart';
import 'package:rollvi/camera_page.dart';
import 'package:rollvi/screens/remote_object.dart';
import 'package:rollvi/screens/augmented_faces.dart';
import 'package:rollvi/trimmer_page.dart';
import 'video_trimmer/video_trimmer.dart';


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
                  "Select Video",
                  style: TextStyle(color: Colors.white)
              ),
              color: Colors.blue,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => SelectVideoPage())
                );
              },
            ),
            RaisedButton(
              child: Text(
                  "Make Video",
                  style: TextStyle(color: Colors.white)
              ),
              color: Colors.blue,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => MakeVideoPage())
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
                    .push(MaterialPageRoute(builder: (context) => CameraPage())
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
                  "CountDown UI",
                  style: TextStyle(color: Colors.white)
              ),
              color: Colors.red,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => CountDownTimer())
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
                    return TrimmerPage(_trimmer);
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