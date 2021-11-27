import 'package:MyThirdEar/cards/pitch.dart';
import 'package:MyThirdEar/cards/speed.dart';
import 'package:MyThirdEar/screens/music_player_screen.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:MyThirdEar/models/library.dart';
import 'package:path_provider/path_provider.dart';

import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:MyThirdEar/utils/common.dart';

class MusicPlayer extends StatefulWidget {
  final AudioFile audioFile;
  MusicPlayerScreenState musicPlayerScreenState;
  MusicPlayer({required this.audioFile, required this.musicPlayerScreenState});
  var callback;

  @override
  _MusicPlayerPlayState createState() => _MusicPlayerPlayState();
}

class _MusicPlayerPlayState extends State<MusicPlayer>
    with WidgetsBindingObserver {
  late AudioPlayer _player;
  var _audioFile;
  var _appDocDir;
  var _callback;
  var loopingMode;
  late Duration loopingStart;
  late Duration loopingEnd;
  var loopingError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _player = new AudioPlayer();
    _audioFile = widget.audioFile;
    loopingMode = "off";
    loopingError = false;
    _callback = pauseAudioOnExit;

    widget.musicPlayerScreenState.waveformConfig.positionDataStream =
        Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
                _player.positionStream.asBroadcastStream(),
                _player.bufferedPositionStream.asBroadcastStream(),
                _player.durationStream.asBroadcastStream(),
                (position, bufferedPosition, duration) => PositionData(
                    position, bufferedPosition, duration ?? Duration.zero))
            .asBroadcastStream();

    _init();
  }

  Future<void> _init() async {
    _appDocDir = await getApplicationDocumentsDirectory();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    widget.callback = _callback;

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

  void pauseAudioOnExit() {
    _player.pause();
  }

  void setStartLoop() {
    setState(() {
      loopingMode = "start";
      loopingStart = _player.position;
    });
  }

  void setEndLoop() async {
    if (_player.position <= loopingStart) {
      loopingError = true;
      showInvalidLoopDialog(context, loopingStart);
      return;
    }
    setState(() {
      loopingMode = "looping";
      loopingEnd = _player.position;
    });

    widget.musicPlayerScreenState.setState(() {
      widget.musicPlayerScreenState.waveformConfig.startPercentage =
          loopingStart.inMilliseconds / _player.duration!.inMilliseconds;
      widget.musicPlayerScreenState.waveformConfig.endPercentage =
          loopingEnd.inMilliseconds / _player.duration!.inMilliseconds;
    });

    await _player.setClip(start: loopingStart, end: loopingEnd);
    await _player.setLoopMode(LoopMode.one);
  }

  void clearLoop() async {
    await _player.setLoopMode(LoopMode.off);

    String applicationDirectory = _audioFile.filepath;
    String audioFilePath = '${_appDocDir.path}/$applicationDirectory';

    setState(() {
      _player.pause();
      _player = new AudioPlayer();
      _player.setFilePath(audioFilePath);
      loopingMode = "off";
    });

    widget.musicPlayerScreenState.setState(() {
      widget.musicPlayerScreenState.waveformConfig.positionDataStream =
          Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
                  _player.positionStream.asBroadcastStream(),
                  _player.bufferedPositionStream.asBroadcastStream(),
                  _player.durationStream.asBroadcastStream(),
                  (position, bufferedPosition, duration) => PositionData(
                      position, bufferedPosition, duration ?? Duration.zero))
              .asBroadcastStream();

      widget.musicPlayerScreenState.waveformConfig.setToDefault();
    });
  }

  void showInvalidLoopDialog(context, loopingStart) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Invalid Loop'),
              content: SingleChildScrollView(
                child: Text(
                    'Please make sure the end of the loop is after the start of the loop, [loop start: $loopingStart].'),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
                body: Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    StreamBuilder<PositionData>(
                      stream: widget.musicPlayerScreenState.waveformConfig
                          .positionDataStream,
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
                    if (loopingMode == "off")
                      Container(
                          child: Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                            onPressed: () => setStartLoop(),
                            icon: Icon(Icons.loop_outlined),
                            label: Text("Start Loop")),
                      )),
                    if (loopingMode == "start")
                      Container(
                          child: Align(
                              alignment: Alignment.center,
                              child: TextButton.icon(
                                  onPressed: () => setEndLoop(),
                                  icon: Icon(Icons.loop_outlined),
                                  label: Text("End Loop")))),
                    if (loopingMode == "looping")
                      Container(
                          child: Align(
                              alignment: Alignment.center,
                              child: TextButton.icon(
                                  onPressed: () => clearLoop(),
                                  icon: Icon(Icons.cancel_outlined),
                                  label: Text("Clear Loop")))),
                    ControlButtons(_player),
                  ],
                )),
        ));
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
                child: SpeedCard(player)),
            Container(
                width: MediaQuery.of(context).size.width / 2,
                decoration: BoxDecoration(
                    border: Border.all(width: 0.5, color: Colors.grey)),
                child: PitchCard(player)),
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
                      height: 40,
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
