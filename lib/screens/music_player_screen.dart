import 'dart:async';
import 'dart:io';

import 'package:MyThirdEar/cards/rta.dart';
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
              _player.callback();
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
        backgroundColor: Colors.blue,
        title: Text(
          'MyThirdEar',
          style: TextStyle(
            fontSize: 25,
          ),
        ),
      )),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          StreamBuilder<String>(
            stream: _player.audioFile.waveformFileController.stream,
            builder:
                (BuildContext __context, AsyncSnapshot<String> __snapshot) {
              if (hideRTA)
                return SizedBox(
                    height: 200,
                    child: FutureBuilder<WaveformData>(
                      future: loadWaveformData(__snapshot.data!),
                      builder: (context, AsyncSnapshot<WaveformData> snapshot) {
                        if (snapshot.hasData) {
                          return PaintedWaveform(
                            sampleData: snapshot.data!,
                            config: waveformConfig,
                          );
                        }
                        return Container(
                          height: 10,
                          child: CircularProgressIndicator(),
                        );
                      },
                    ));
              return SizedBox();
            },
          ),
          Container(
            height: 220,
            child: _player,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Hide Spectrogram'),
                  Checkbox(
                      value: hideRTA,
                      onChanged: (value) {
                        setState(() {
                          hideRTA = value!;
                        });
                      }),
                ],
              ),
            ],
          ),
          hideRTA
              ? Flexible(
                  child: Container(
                  height: 80,
                  child: RTACard(_player.audioFile.predictionPath,
                      waveformConfig: waveformConfig,
                      height: 80,
                      width: MediaQuery.of(context).size.width),
                ))
              : SizedBox(),
          !hideRTA
              ? Flexible(
                  flex: 1,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Image.file(
                      new File(_player.audioFile.spectrogramPath),
                      height: 500,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.fill,
                    ),
                  ),
                )
              : SizedBox(),
          hideRTA
              ? Container(
                  height: 150,
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
