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
  ScrollController _scrollController = ScrollController();
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<String>(
                    stream: _player.audioFile.waveformFileController.stream,
                    builder: (BuildContext __context,
                        AsyncSnapshot<String> __snapshot) {
                      if (hideRTA)
                        return SizedBox(
                        height: 200,
                        child: FutureBuilder<WaveformData>(
                          future: loadWaveformData(__snapshot.data!),
                          builder:
                              (context, AsyncSnapshot<WaveformData> snapshot) {
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
                        if (!hideRTA) {
                          Timer.periodic(Duration(milliseconds: 100), (timer) {
                            timer.cancel();
                            _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent);
                          });
                        }
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
              : Flexible(
                flex: 1,
                  child: Container(
                    decoration: new BoxDecoration(color: Colors.black),
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: SingleChildScrollView(
                        reverse:true,
                        controller: _scrollController,
                        child: Container(
                          padding: EdgeInsets.only(top: 200),
                          child: Image.asset(
                            'assets/images/demo.jpg',
                            height: MediaQuery.of(context).size.height,
                            fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  )
                ),
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
                  height: 90,
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
