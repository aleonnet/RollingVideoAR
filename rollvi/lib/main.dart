import 'package:flutter/material.dart';
import 'package:rollvi/home.dart';

import 'test/countdown_timer.dart';

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
        home: new CountDownTimer()
    );
  }
}
