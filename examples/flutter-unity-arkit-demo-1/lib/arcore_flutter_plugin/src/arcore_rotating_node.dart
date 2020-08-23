import 'arcore_node.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

import 'shape/arcore_shape.dart';

class ArCoreRotatingNode extends ArCoreNode {
  ArCoreRotatingNode({
    this.shape,
    double degreesPerSecond,
    Vector3 position,
    Vector3 scale,
    Vector4 rotation,
    String name,
  })  : degreesPerSecond = ValueNotifier(90.0),
        super(
          shape: shape,
          name: name,
          position: position,
          scale: scale,
        );

  final ArCoreShape shape;

  final ValueNotifier<double> degreesPerSecond;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'degreesPerSecond': this.degreesPerSecond.value,
      }
        ..addAll(super.toMap())
        ..removeWhere((String k, dynamic v) => v == null);
}
