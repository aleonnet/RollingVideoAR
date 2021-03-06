import 'package:flutter/material.dart';
import 'package:rollvi/const/app_colors.dart';


class InstaLinkDialog extends StatefulWidget {
  final clipData;

  InstaLinkDialog({Key key, this.clipData}) : super(key: key);

  @override
  _InstaLinkDialogState createState() => _InstaLinkDialogState();
}

class _InstaLinkDialogState extends State<InstaLinkDialog> {
  String inputStr;
  TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    inputStr = widget.clipData;
    textController.text = inputStr;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Consts.padding),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
            top: Consts.avatarRadius,
            bottom: Consts.padding / 2,
            left: Consts.padding,
            right: Consts.padding,
          ),
          margin: EdgeInsets.only(top: Consts.avatarRadius),
          decoration: new BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(Consts.padding),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // To make the card compact
            children: <Widget>[
              Text(
                '인스타그램에서 비디오 링크를 복사해주세요',
                style: TextStyle(
                  fontSize: 16.0,
                  color: AppColor.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                autofocus: false,
                controller: textController,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColor.lightText),
                onChanged: (value) {
                  inputStr = value;
                },
              ),
              SizedBox(height: 24.0),
              Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatButton(
                          child: Text('Cancel', style: TextStyle(color: AppColor.rollviBackgroundPoint),),
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                      FlatButton(
                        child: Text('Ok', style: TextStyle(color: AppColor.rollviAccent),),
                        onPressed: () {
                          Navigator.of(context).pop(inputStr);
                        },
                      ),
                    ],
                  )),
            ],
          ),
        ),
        Positioned(
          top: 20,
          left: Consts.padding,
          right: Consts.padding,
          child: Image(
            image: AssetImage('assets/instagram_icon.png'),
            width: 80,
            height: 80,
          ),
        ),
      ],
    );
  }
}

class Consts {
  Consts._();

  static const double padding = 30.0;
  static const double avatarRadius = 65.0;
}