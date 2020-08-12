import 'package:flutter/material.dart';
import 'package:rollvi/capture_camera.dart';
import 'package:rollvi/screens/remote_object.dart';
import 'package:rollvi/screens/augmented_faces.dart';
import 'package:rollvi/record_video.dart';

import 'record_video.dart';

class HomeScreen extends StatelessWidget{
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
                  "AR Plane",
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
              onPressed: () {

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