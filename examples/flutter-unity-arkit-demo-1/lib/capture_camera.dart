import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:rollvi/darwin_camera//darwin_camera.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class CaptureCamera extends StatefulWidget {
  const CaptureCamera({Key key}) : super(key: key);

  @override
  _CaptureCamera createState() => _CaptureCamera();
}

class _CaptureCamera extends State<CaptureCamera> {
  File imageFile;
  bool isImageCaptured;

  @override
  void initState() {
    super.initState();
    isImageCaptured = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: openCamera(context),
      )
    );
  }

  openCamera(BuildContext context) async {
    PermissionHandler permissionHandler = PermissionHandler();

    await checkForPermissionBasedOnPermissionGroup(
      permissionHandler,
      PermissionGroup.camera,
    );

    await checkForPermissionBasedOnPermissionGroup(
      permissionHandler,
      PermissionGroup.microphone,
    );


    ///
    String filePath = await FileUtils.getDefaultFilePath();
    String uuid = DateTime.now().millisecondsSinceEpoch.toString();

    ///
    filePath = '$filePath/$uuid.png';

    List<CameraDescription> cameraDescription = await availableCameras();

    ////
    DarwinCameraResult result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DarwinCamera(
          cameraDescription: cameraDescription,
          filePath: filePath,
          resolution: ResolutionPreset.high,
          defaultToFrontFacing: true,
          quality: 100,
        ),
      ),
    );

    ///
    if (result != null && result.isFileAvailable) {
      setState(() {
        isImageCaptured = true;
        imageFile = result.file;
      });
      print(result.file);
      print(result.file.path);
    }
  }

}


Future<bool> checkForPermissionBasedOnPermissionGroup(
    PermissionHandler permissionHandler,
    PermissionGroup permissionType,
    ) async {
  ///
  PermissionStatus permission;
  permission = await permissionHandler.checkPermissionStatus(permissionType);
  if (permission == PermissionStatus.granted) {
    // takeImageFromCameraAndSave();
    return true;
  }
  var status = await permissionHandler.requestPermissions([permissionType]);
  permission = status[permissionType];

  if (permission == PermissionStatus.granted) {
    // takeImageFromCameraAndSave();
    return true;
  } else {
    ///
    /// ASK USER TO GO TO SETTINGS TO GIVE PERMISSION;

    return false;
  }
}

class FileUtils {
  static Future<String> getDefaultFilePath() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String mediaDirectory = appDocDir.path + "/media";
      Directory(mediaDirectory).create(recursive: true);
      return mediaDirectory;
    } catch (error, stacktrace) {
      print('could not create folder for media assets');
      print(error);
      print(stacktrace);
      return null;
    }
  }
}
