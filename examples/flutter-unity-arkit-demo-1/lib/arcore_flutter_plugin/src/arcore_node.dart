import 'utils/vector_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';
import 'utils/random_string.dart'
    as random_string;
import 'shape/arcore_shape.dart';

class ArCoreNode {
  ArCoreNode({
    this.shape,
    String name,
    Vector3 position,
    Vector3 scale,
    Vector4 rotation,
    this.children = const [],
  })  : name = name ?? random_string.randomString(),
        position = ValueNotifier(position),
        scale = ValueNotifier(scale),
        rotation = ValueNotifier(rotation);

  final List<ArCoreNode> children;

  final ArCoreShape shape;

  final ValueNotifier<Vector3> position;

  final ValueNotifier<Vector3> scale;

  final ValueNotifier<Vector4> rotation;

  final String name;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'dartType': runtimeType.toString(),
        'shape': shape?.toMap(),
        'position': convertVector3ToMap(position.value),
        'scale': convertVector3ToMap(scale.value),
        'rotation': convertVector4ToMap(rotation.value),
        'name': name,
        'children':
            this.children.map((arCoreNode) => arCoreNode.toMap()).toList(),
      }..removeWhere((String k, dynamic v) => v == null);
}
