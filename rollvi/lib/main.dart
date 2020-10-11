import 'package:flutter/material.dart';
import 'package:rollvi/concat_video_page.dart';
import 'package:rollvi/home.dart';
import 'package:rollvi/preview/sequence_preview_page.dart';
import 'package:rollvi/result_page.dart';

import 'camera_page.dart';
import 'home.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
        theme: ThemeData(
          primarySwatch: Colors.red,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: <String, WidgetBuilder> {
          '/home': (BuildContext context) => new HomePage(),
          '/camera': (BuildContext context) => new CameraPage(),
          '/preview': (BuildContext context) => new SequencePreviewPage(),
          '/concat': (BuildContext context) => new ConcatVideoPage(),
          '/result': (BuildContext context) => new ResultPage(),
        },
    );
  }
}
