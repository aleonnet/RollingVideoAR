import 'package:flutter/material.dart';


class InstaLinkDialog extends StatefulWidget {
  final clipData;

  InstaLinkDialog({Key key, this.clipData}) : super(key: key);

  @override
  _InstaLinkDialogState createState() => _InstaLinkDialogState();
}

class _InstaLinkDialogState extends State<InstaLinkDialog> {
  String inputStr;

  @override
  void initState() {
    inputStr = widget.clipData;
    super.initState();
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
            top: Consts.avatarRadius + Consts.padding,
            bottom: Consts.padding,
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
                'Instagram Video Link',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                autofocus: true,
                decoration: new InputDecoration(
                    labelText: 'Instagram Link', hintText: inputStr),
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
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                      FlatButton(
                        child: Text('Ok'),
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
            width: 100,
            height: 100,
          ),
        ),
      ],
    );
  }
}

class Consts {
  Consts._();

  static const double padding = 16.0;
  static const double avatarRadius = 66.0;
}