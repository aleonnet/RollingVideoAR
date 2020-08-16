import 'dart:math';

import 'package:rollvi/arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class FloorObjectPage extends StatefulWidget {
  @override
  _FloorObjectPageState createState() => _FloorObjectPageState();
}

class _FloorObjectPageState extends State<FloorObjectPage> {
  ArCoreController arCoreController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Floor Object'),
        ),
        body: ArCoreView(
          onArCoreViewCreated: _onArCoreViewCreated,
          enableTapRecognizer: true,
        ),
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController.onNodeTap = (name) => onTapHandler(name);
    arCoreController.onPlaneTap = _handleOnPlaneTap;
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;

    arCoreController.addArCoreNodeWithAnchor(
      ArCoreReferenceNode(
        name: 'andy',
        object3DFileName: 'Andy.sfb',
        position: hit.pose.translation,
        rotation: hit.pose.rotation,
      )
    );

    _addMatrix3D(arCoreController, hit);
  }

  void onTapHandler(String name) {
    print("Flutter: onNodeTap");
    showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(content: Text('onNodeTap on $name')),
    );
  }

  void _addMatrix3D(
      ArCoreController arCoreController, ArCoreHitTestResult hit) {
    final List<ArCoreNode> list = [];
    for (int i = 0; i < 8; i++) {
      for (int z = 0; z < 8; z++) {
        list.add(createNode(createCube(), i, z));
      }
    }

    final node = ArCoreNode(
      shape: null,
      position: hit.pose.translation + vector.Vector3(0.0, 0.5, 0.0),
      rotation: hit.pose.rotation,
      children: list,
    );

    arCoreController.addArCoreNodeWithAnchor(node);
  }

  createNode(ArCoreCube shape, int i, int z) {
    final cubeNode = ArCoreNode(
      shape: shape,
      position: vector.Vector3(0.1 * z, 0.0, -0.1 * i),
    );

    return cubeNode;
  }

  createCube() {
    final material = ArCoreMaterial(
      color: Color.fromARGB(255, Random().nextInt(255), Random().nextInt(255),
          Random().nextInt(255)),
      metallic: 1.0,
    );
    final cube = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.1, 0.1, 0.1),
    );

    return cube;
  }
}
