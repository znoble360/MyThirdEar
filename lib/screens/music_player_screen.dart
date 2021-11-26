import 'dart:async';

import 'package:MyThirdEar/models/library.dart';
import 'package:MyThirdEar/models/waveformConfig.dart';
import 'package:MyThirdEar/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:MyThirdEar/cards/waveform.dart';

import 'package:MyThirdEar/plugins/app_review/app_review.dart';
import 'package:MyThirdEar/screens/library.dart';
import 'package:MyThirdEar/screens/player.dart';
import 'package:MyThirdEar/ui/common/index.dart';
import 'package:MyThirdEar/ui/common/piano_view.dart';
import 'package:MyThirdEar/utils/waveform.dart';

class MusicPlayerScreen extends StatefulWidget {
  final AudioFile audioFile;

  MusicPlayerScreen({required this.audioFile});

  @override
  MusicPlayerScreenState createState() => MusicPlayerScreenState();
}

class MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver {
  bool canVibrate = false;
  bool hideRTA = true;
  late MusicPlayer _player;
  WaveformConfig waveformConfig = WaveformConfig();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 60)).then((_) {
      if (mounted) ReviewUtils.requestReview();
    });
    _player = MusicPlayer(
      audioFile: widget.audioFile,
      musicPlayerScreenState: this,
    );
  }

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          hideRTA
              ? SizedBox(
              height: 160,
              child: StreamBuilder<String>(
                stream: _player.audioFile.waveformFileController.stream,
                builder:
                    (BuildContext __context, AsyncSnapshot<String> __snapshot) {
                  return FutureBuilder<WaveformData>(
                    future: loadWaveformData(__snapshot.data!),
                    builder: (context, AsyncSnapshot<WaveformData> snapshot) {
                      if (snapshot.hasData) {
                        return PaintedWaveform(
                          sampleData: snapshot.data!,
                          config: waveformConfig,
                        );
                      }
                      return CircularProgressIndicator(
                          color: Colors.blueAccent);
                    },
                  );
                    },
                  ))
              : Container(height: 1),
          Container(
            height: 300,
            child: _player,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hide Spectrogram'),
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
          hideRTA
              ? Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text('Estimated Chord'),
                        Text('Cmaj7'),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Estimated BPM'),
                        Text('117'),
                      ],
                    ),
                  ],
                )
              : Container(
                  height: 310,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Image.asset(
                      'assets/images/demo.jpg',
                      height: 500,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
          SizedBox(height: hideRTA ? 70 : 0),
          hideRTA
              ? Flexible(
                  child: PianoView(
                    keyWidth: (80 * (0.5)),
                    showLabels: true,
                    labelsOnlyOctaves: false,
                    disableScroll: false,
                    feedback: false,
                  ),
                )
              : Container(
                  height: 82,
                  child: Image.asset(
                    'assets/images/piano.png',
                    fit: BoxFit.fill,
                  ),
                )
        ],
      ),
    );
  }
}
