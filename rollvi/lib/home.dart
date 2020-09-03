import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollvi/concat_rollvi_page.dart';
import 'package:rollvi/select_video_page.dart';
import 'package:rollvi/camera_page.dart';

class HomeScreen extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          child: Row(
            children: <Widget>[

              FloatingActionButton(
                heroTag: null,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.camera_alt),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) => CameraPage())
                  );
                },
              ),

              FloatingActionButton(
                  heroTag: null,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.image),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) => SelectVideoPage())
                  );
                },
              ),
            ],
//            mainAxisAlignment: MainAxisAlignment.center,
          )
      ),
    );
  }
}