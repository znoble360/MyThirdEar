import 'dart:async';

import 'package:flutter/material.dart';

import 'package:musictranscriptiontools/plugins/app_review/app_review.dart';
import 'package:musictranscriptiontools/screens/library.dart';
import 'package:musictranscriptiontools/screens/player.dart';
import 'package:musictranscriptiontools/ui/common/index.dart';
import 'package:musictranscriptiontools/ui/common/piano_view.dart';

class MusicPlayerScreen extends StatefulWidget {
  final MusicPlayer player;

  MusicPlayerScreen({required this.player});

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver {
  bool canVibrate = false;
  bool hideRTA = true;
  var _player;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 60)).then((_) {
      if (mounted) ReviewUtils.requestReview();
    });
    _player = widget.player;
  }

  onChanged() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          child: SafeArea(
        child: ListView(children: <Widget>[
          Container(height: 20.0),
          ListTile(
            title: Text("Return Home Page"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Library(),
                ),
              );
            },
          ),
        ]),
      )),
      appBar: (AppBar(
        title: Text(
          'MyThirdEar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Indies',
            fontSize: 25.0,
          ),
        ),
      )),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 80),
          Container(
            height: 250,
            child: _player,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Show Spectrogram'),
                Checkbox(
                    value: hideRTA,
                    onChanged: (value) {
                      setState(() {
                        hideRTA = value!;
                      });
                    })
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(hideRTA ? 'Estimated Chord' : ''),
                  Text(hideRTA ? 'Cmaj7' : ''),
                ],
              ),
              Column(
                children: [
                  Text(hideRTA ? 'Estimated BPM' : ''),
                  Text(hideRTA ? '117' : ''),
                ],
              ),
            ],
          ),
          SizedBox(height: 30),
          Flexible(
            child: PianoView(
              keyWidth: (80 * (0.5)),
              showLabels: true,
              labelsOnlyOctaves: false,
              disableScroll: false,
              feedback: false,
            ),
          )
        ],
      ),
    );
  }
}