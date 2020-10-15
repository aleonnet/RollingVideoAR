import 'package:flutter/material.dart';
import 'package:rollvi/const/app_colors.dart';
import 'package:rollvi/const/app_size.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    final _deviceRatio = _size.width / _size.height;

    MediaQueryData mediaQuery = MediaQuery.of(context);
    mediaQuery.devicePixelRatio;
    mediaQuery.size.height;
    mediaQuery.size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(AppSize.AppBarHeight),
        child: AppBar(
          title: Text('ROLLVI'),
          centerTitle: true,
        ),
      ),
      backgroundColor: AppColor.dismissibleBackground,
      body: Column(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                image: DecorationImage(
                    image: AssetImage("assets/intro_family.gif"),
                    fit: BoxFit.cover)),
          ),
          Expanded(
            child: Container(
              child: FloatingActionButton(
                heroTag: null,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/camera');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}