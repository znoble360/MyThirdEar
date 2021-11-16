import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musictranscriptiontools/cards/pitch.dart';
import 'package:musictranscriptiontools/cards/speed.dart';
import 'package:musictranscriptiontools/models/library.dart';
import 'package:path_provider/path_provider.dart';

import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:musictranscriptiontools/utils/common.dart';

class MusicPlayer extends StatefulWidget {
  final AudioFile audioFile;
  MusicPlayer({required this.audioFile});

  @override
  _MusicPlayerPlayState createState() => _MusicPlayerPlayState();
}

class _MusicPlayerPlayState extends State<MusicPlayer>
    with WidgetsBindingObserver {
  var _player;
  var _audioFile;
  var _appDocDir;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _player = new AudioPlayer();
    _audioFile = widget.audioFile;

    _init();
  }

  Future<void> _init() async {
    _appDocDir = await getApplicationDocumentsDirectory();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    try {
      String applicationDirectory = _audioFile.filepath;
      String audioFilePath = '${_appDocDir.path}/$applicationDirectory';
      print((audioFilePath));

      await _player.setAudioSource(AudioSource.uri(Uri.file(audioFilePath)),
          initialPosition: Duration.zero, preload: true);
    } catch (e) {
      print("Error loading audio source: $e");
    }

    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player.stop();
    }
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
              child: Container(
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StreamBuilder<PositionData>(
                stream: _positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data;
                  return SeekBar(
                    duration: positionData?.duration ?? Duration.zero,
                    position: positionData?.position ?? Duration.zero,
                    bufferedPosition:
                        positionData?.bufferedPosition ?? Duration.zero,
                    onChangeEnd: (newPosition) {
                      _player.seek(newPosition);
                    },
                  );
                },
              ),
              ControlButtons(_player),
            ],
          ))),
        ),
      ),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  ControlButtons(this.player);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 2,
              decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: Colors.grey)),
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      IconButton(
                        icon: Icon(Icons.minimize),
                        onPressed: () {
                          if (player.speed > 0.5) {
                            var speed = player.speed - 0.1;
                            player.setSpeed(speed);
                          }
                        },
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 30),
                        child: Text('Speed'),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (player.speed < 1.5) {
                            var speed = player.speed + 0.1;
                            player.setSpeed(speed);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: Colors.grey)),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_drop_down),
                        onPressed: () {
                          if (player.pitch > 0) {
                            var newPitch = player.pitch - 0.1;
                            player.setPitch(newPitch);
                            debugPrint('$newPitch');
                          }
                        },
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 30),
                        child: Text('Pitch'),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_drop_up),
                        onPressed: () {
                          if (player.pitch < 1.5) {
                            var newPitch = player.pitch + 0.1;
                            player.setPitch(newPitch);
                            debugPrint('$newPitch');
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 3,
              decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: Colors.grey)),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<SequenceState>(
                    // stream: player.sequenceStateStream,
                    builder: (context, snapshot) => IconButton(
                      icon: Icon(Icons.skip_previous),
                      onPressed:
                          player.hasPrevious ? player.seekToPrevious : null,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 3,
              decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: Colors.grey)),
              alignment: Alignment.center,
              child: StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;
                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      height: 47,
                      child: CircularProgressIndicator(),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: Icon(Icons.play_arrow),
                      //iconSize: 64.0,
                      onPressed: player.play,
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return IconButton(
                      icon: Icon(Icons.pause),
                      //iconSize: 64.0,
                      onPressed: player.pause,
                    );
                  } else {
                    return IconButton(
                      icon: Icon(Icons.replay),
                      //iconSize: 64.0,
                      onPressed: () => player.seek(Duration.zero,
                          index: player.effectiveIndices!.first),
                    );
                  }
                },
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 3,
              decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: Colors.grey)),
              child: StreamBuilder<SequenceState>(
                // stream: player.sequenceStateStream
                builder: (context, snapshot) => IconButton(
                  icon: Icon(Icons.skip_next),
                  onPressed: player.hasNext ? player.seekToNext : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
