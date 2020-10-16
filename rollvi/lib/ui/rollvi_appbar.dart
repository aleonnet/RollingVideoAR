import "package:flutter/material.dart";
import 'package:rollvi/const/app_size.dart';

class RollviAppBar extends AppBar {
  final BuildContext context;
  final bool homeIcon;
  final bool backIcon;
  final String backPage;

  RollviAppBar(this.context,
      {Key key, this.homeIcon = true, this.backIcon = false, this.backPage = ''});

  @override
  Widget get title =>
      Image.asset('assets/logo_text_wh.png', height: AppSize.AppBarHeight * 0.45);

  @override
  // TODO: implement centerTitle
  bool get centerTitle => true;

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(AppSize.AppBarHeight);

//  @override
//  // TODO: implement elevation
//  double get elevation => 0.0;

  @override
  // TODO: implement flexibleSpace
  Widget get flexibleSpace => Container(
          decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.redAccent],
            begin: const FractionalOffset(0.0, 0.0),
            end: const FractionalOffset(0.5, 0.0),
            stops: [0.0, 1.0],
            tileMode: TileMode.clamp),
      ));

  @override
  // TODO: implement actions
  List<Widget> get actions => [
        (homeIcon == true)
            ? new IconButton(
                icon: Icon(
                  Icons.home,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              )
            : Container(),
      ];

  @override
  // TODO: implement leading
  Widget get leading => (backIcon == true) ? IconButton(
      icon: Icon(
        Icons.keyboard_backspace,
        color: Colors.white,
      ),
      onPressed: () {
        if (backPage != '') {
          Navigator.of(context).popAndPushNamed(backPage);
        }
        else {
          Navigator.of(context).pop();
        }
      }) : Container();
}
