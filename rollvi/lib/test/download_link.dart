import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';


class TestScreen extends StatelessWidget{

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
                    "Download",
                    style: TextStyle(color: Colors.white)
                ),
                color: Colors.blue,
                onPressed: () async {

                  String url = 'https://www.instagram.com/p/CER0Q1UIIbG/?igshid=1pne2w3lqs0e3';
                  String directory = (await getExternalStorageDirectory()).path;
                  downloadFile(url, "instavideo.mp4", directory);

                },
              ),
             ]
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

  Future<String> downloadFile(String url, String fileName, String dir) async {
    HttpClient httpClient = new HttpClient();
    File file;
    String filePath = '';
    String myUrl = '';

    try {
      myUrl = url+'/'+fileName;
      var request = await httpClient.getUrl(Uri.parse(myUrl));
      var response = await request.close();
      if(response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        filePath = '$dir/$fileName';
        file = File(filePath);
        await file.writeAsBytes(bytes);
      }
      else
        filePath = 'Error code: '+response.statusCode.toString();
    }
    catch(ex){
      filePath = 'Can not fetch url';
    }

    print(filePath);

    return filePath;
  }
}