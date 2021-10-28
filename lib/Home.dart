import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musictranscriptiontools/ui/home/screen.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  TextEditingController controller = TextEditingController();
  List<String> data = [
    'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    'https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3',
  ];
  List<String> musics = [];

  @override
  void initState() {
    super.initState();
    musics.addAll(data);
  }

  search(String key) {
    musics.clear();
    if (key == null || key == '') {
      musics.addAll(data);
    } else {
      data.forEach((element) {
        if (element.contains(key)) {
          musics.add(element);
        }
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
            child: SafeArea(
          child: ListView(children: <Widget>[
            Container(height: 20.0),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Pick Music File"),
              onTap: () {
                // Navigator.of(context).push(
                //     MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
          ]),
        )),
        body: Material(
            child: Stack(
          children: [
            Container(
                color: Colors.white,
                padding: EdgeInsets.only(bottom: 600.h),
                child: SingleChildScrollView(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    getTopView(),
                    getSearchView(),
                    Container(
                        padding: EdgeInsets.only(left: 30.w),
                        child: Text('My Library',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 48.sp,
                                decoration: TextDecoration.none))),
                    for (String url in musics) getMusicListItem(url),
                    SizedBox(height: 30.h),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: Colors.black,
                          size: 80.w,
                        ),
                        SizedBox(width: 30.w)
                      ],
                    )
                  ],
                ))),
            // Align(
            //   alignment: Alignment.bottomLeft,
            //   child: getBottomView(),
            // )
          ],
        )));
  }

  getBottomView() {
    return Container(
      height: 150.h,
      decoration: BoxDecoration(
        color: Color(0xFFBBDEFB),
      ),
      child: Row(
        children: [
          SizedBox(width: 50.w),
          Text('In The Mood - Glenn Miller',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 40.sp,
                  decoration: TextDecoration.none)),
          SizedBox(width: 200.w),
          Icon(
            Icons.chevron_right,
            color: Colors.black,
          )
        ],
      ),
    );
  }

  getMusicListItem(String url) {
    List<String> strs = url.split('/');
    String musicName = strs[strs.length - 1];
    String musicAuthor = strs[strs.length - 2];
    return GestureDetector(
        onTap: () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) {
            return HomeScreen(url: url);
          }));
        },
        child: Container(
          margin: EdgeInsets.only(left: 30.w, right: 30.w, top: 30.w),
          padding: EdgeInsets.all(30.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15.w)),
            color: Color(0xFFBBDEFB),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                Icons.music_note,
                color: Colors.black,
              ),
              SizedBox(width: 15.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(musicName,
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 40.sp,
                          decoration: TextDecoration.none)),
                  SizedBox(height: 15.h),
                  Text(musicAuthor,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 36.sp,
                          decoration: TextDecoration.none))
                ],
              )
            ],
          ),
        ));
  }

  getSearchView() {
    return Container(
      margin: EdgeInsets.all(60.w),
      height: 110.h,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.w),
          borderRadius: BorderRadius.all(Radius.circular(60.h))),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(width: 30.w),
          Icon(
            Icons.search,
            color: Colors.black,
          ),
          Container(
              width: 200,
              height: 120.h,
              padding: EdgeInsets.only(left: 10.w),
              child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 42.sp,
                  ),
                  onSubmitted: (v) {
                    search(v);
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none, // 去掉下滑线
                    counterText: '', // 去除输入框底部的字符计数
                  )))
        ],
      ),
    );
  }

  getTopView() {
    return Container(
      height: 100.h,
      padding: EdgeInsets.only(top: 30.h),
      child: Row(
        children: [
          SizedBox(width: 30.w),
          Builder(builder: (context) {
            return GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Icon(
                  Icons.dehaze,
                  color: Colors.black,
                ));
          }),
          SizedBox(width: 170.w),
          Text(
            'MyThirdEar',
            style: TextStyle(
                color: Colors.black,
                fontSize: 60.sp,
                decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }
}
