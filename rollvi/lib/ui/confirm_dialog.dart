import 'package:flutter/material.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_path.dart';

class ConfirmDialog extends StatefulWidget {
  ConfirmDialog({Key key}) : super(key: key);

  @override
  _ConfirmDialogState createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  String inputStr;
  TextEditingController textController;

  @override
  void initState() {
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
      children: [
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '작업한 모든 내용이 초기화 됩니다\n홈으로 돌아가시겠습니까?',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: AppColor.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
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
                          onPressed: () async {
                            await clearRollviTempDir();
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          },
                        ),
                      ],
                    )),
              ],
            )),
        Positioned(
          top: 20,
          left: Consts.padding,
          right: Consts.padding,
          child: Image(
            image: AssetImage('assets/logo_round.png'),
            width: 80,
            height: 80,
          )
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
