import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musictranscriptiontools/cards/pitch.dart';
import 'package:musictranscriptiontools/cards/speed.dart';
import 'package:musictranscriptiontools/utils/file_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'utils/common.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AudioPlayer _player;
<<<<<<< Updated upstream
=======
  final _playlist = ConcatenatingAudioSource(children: [
    ClippingAudioSource(
      start: Duration(seconds: 60),
      end: Duration(seconds: 90),
      child: AudioSource.uri(Uri.parse(
          "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3")),
      tag: AudioMetadata(
        album: "Science Friday",
        title: "A Salute To Head-Scratching Science (30 seconds)",
        artwork:
        "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      ),
    ),
    AudioSource.uri(
      Uri.parse(
          "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3"),
      tag: AudioMetadata(
        album: "Science Friday",
        title: "A Salute To Head-Scratching Science",
        artwork:
        "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      ),
    ),
    AudioSource.uri(
      Uri.parse("https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3"),
      tag: AudioMetadata(
        album: "Science Friday",
        title: "From Cat Rheology To Operatic Incompetence",
        artwork:
        "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      ),
    ),
  ]);
  int _addedCount = 0;
>>>>>>> Stashed changes
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  String _outputPath = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  Future<void> _init() async {
    // Open Documents Directory
    Directory appDocumentDir = await getApplicationDocumentsDirectory();
    String rawDocumentPath = appDocumentDir.path;

    _outputPath = rawDocumentPath;

    // TODO: To write an mp3, get the path first and then write as bytes as shown here: https://pub.dev/documentation/mp3editor/latest/

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
<<<<<<< Updated upstream
      print('A stream error occurred: $e');
    });
=======
          print('A stream error occurred: $e');
        });
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      // Catch load errors: 404, invalid url...
      print("Error loading audio source: $e");
    }
>>>>>>> Stashed changes
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
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
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
        key: _globalKey,
<<<<<<< Updated upstream
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            selectFileForPlayer(_player, _outputPath);
          },
          child: const Icon(Icons.file_upload),
          backgroundColor: Colors.yellowAccent,
        ),
=======
        drawer: Drawer(
            child: Column(
              children: [
                SizedBox(height: 60),
                Text('Setting'),
                Container(
                  height: 240.0,
                  padding: EdgeInsets.only(top: 20),
                  child: StreamBuilder<SequenceState?>(
                    stream: _player.sequenceStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final sequence = state?.sequence ?? [];
                      return ReorderableListView(
                        onReorder: (int oldIndex, int newIndex) {
                          if (oldIndex < newIndex) newIndex--;
                          _playlist.move(oldIndex, newIndex);
                        },
                        children: [
                          for (var i = 0; i < sequence.length; i++)
                            Dismissible(
                              key: ValueKey(sequence[i]),
                              background: Container(
                                color: Colors.redAccent,
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(Icons.delete, color: Colors.white),
                                ),
                              ),
                              onDismissed: (dismissDirection) {
                                _playlist.removeAt(i);
                              },
                              child: Material(
                                color: i == state!.currentIndex
                                    ? Colors.grey.shade300
                                    : null,
                                child: ListTile(
                                  title: Text(sequence[i].tag.title as String),
                                  onTap: () {
                                    _player.seek(Duration.zero, index: i);
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            )),
>>>>>>> Stashed changes
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                  onTap: () {
                    _globalKey.currentState?.openDrawer();
                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: Icon(Icons.dehaze, color: Colors.grey),
                  )),
              SizedBox(height: 8.0),
              Row(
                children: [],
              ),
              SizedBox(height: 400),
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
          ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up),
                    onPressed: () {
                      showSliderDialog(
                        context: context,
                        title: "Adjust volume",
                        divisions: 10,
                        min: 0.0,
                        max: 1.0,
                        value: player.volume,
                        stream: player.volumeStream,
                        onChanged: player.setVolume,
                      );
                    },
                  ),
                  StreamBuilder<SequenceState?>(
                    stream: player.sequenceStateStream,
                    builder: (context, snapshot) => IconButton(
                      icon: Icon(Icons.skip_previous),
                      onPressed:
                      player.hasPrevious ? player.seekToPrevious : null,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return Container(
                    margin: EdgeInsets.all(8.0),
                    // width: 64.0,
                    // height: 64.0,
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
            Container(
              width: 100,
              child: StreamBuilder<SequenceState?>(
                stream: player.sequenceStateStream,
                builder: (context, snapshot) => IconButton(
                  icon: Icon(Icons.skip_next),
                  onPressed: player.hasNext ? player.seekToNext : null,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SpeedCard(player),
            PitchCard(player),
          ],
        ),
      ],
    );
  }
}
<<<<<<< Updated upstream
=======

class AudioMetadata {
  final String album;
  final String title;
  final String artwork;

  AudioMetadata({
    required this.album,
    required this.title,
    required this.artwork,
  });
}
>>>>>>> Stashed changes
