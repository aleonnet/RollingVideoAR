import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:rollvi/face_detect.dart';
import 'home.dart';


void main() {
  runApp(App());
}

class App extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ROLLVI',
        theme: ThemeData(
          primarySwatch: Colors.red,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: new RealtimeFaceDetect()
    );
  }
}
