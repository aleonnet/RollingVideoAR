import 'package:flutter/material.dart';
import 'face_detect.dart';

import 'package:rollvi_exhibit/screens/remote_object.dart';
import 'package:rollvi_exhibit/screens/augmented_faces.dart';


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