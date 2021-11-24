import 'dart:async';

import 'package:MyThirdEar/models/library.dart';
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
  late Stream<PositionData> positionDataStream;

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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
              height: 160,
              child: StreamBuilder<String>(
                stream: _player.audioFile.waveformFileController.stream,
                builder:
                    (BuildContext __context, AsyncSnapshot<String> __snapshot) {
                  return FutureBuilder<WaveformData>(
                    future: loadWaveformData(__snapshot.data!),
                    builder: (context, AsyncSnapshot<WaveformData> snapshot) {
                      if (snapshot.hasData) {
                        print("Calling snapshot has data");
                        return PaintedWaveform(
                          sampleData: snapshot.data,
                          positionDataStream: positionDataStream,
                        );
                      }
                      return CircularProgressIndicator(
                          color: Colors.blueAccent);
                    },
                  );
                },
              )),
          Container(
            height: 280,
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
          SizedBox(height: 70),
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
              : SizedBox(height: 0)
        ],
      ),
    );
  }
}
