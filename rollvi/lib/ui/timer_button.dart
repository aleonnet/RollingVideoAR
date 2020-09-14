import 'package:flutter/material.dart';
import 'package:rollvi/ui/progress_painter.dart';


class TimerButton extends FloatingActionButton {

  AnimationController controller;
  TickerProviderStateMixin context;

  TimerButton(TickerProviderStateMixin _context, int _seconds) {
    context = _context;
    controller = AnimationController(
      vsync: context,
      duration: Duration(seconds: _seconds),
    );
  }

  String get timerString {
    Duration duration = controller.duration * controller.value;
//    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    return (duration.inSeconds % 60).toString();
  }

  @override
  Color get backgroundColor => Colors.white;

  @override
  get onPressed {
    print("OnPressed");

    super.onPressed;
    if (controller.isAnimating)
      controller.stop();
    else {
      controller.reverse(
          from: controller.value == 0.0
              ? 1.0
              : controller.value);
    }
  }


  @override
  Widget get child => AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: FractionalOffset.center,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: CustomPaint(
                                  painter: ProgressTimerPainter(
                                    animation: controller,
                                    backgroundColor: Colors.white,
                                    color: Colors.redAccent,
                                  )),
                            ),
                            Align(
                              alignment: FractionalOffset.center,
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    timerString,
                                    style: TextStyle(
                                        fontSize: 15.0,
                                        color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
  );

}