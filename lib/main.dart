import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'common.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AudioPlayer _player;
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
    AudioSource.uri(
      Uri.parse("asset:///audio/nature.mp3"),
      tag: AudioMetadata(
        album: "Public Domain",
        title: "Nature Sounds",
        artwork:
            "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      ),
    ),
  ]);
  int _addedCount = 0;
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();

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

  doSpeed(bool add) {}

  Future<void> _init() async {

    // Using path provider to get the output path for the created file
    // *TO-DO: if the raw document path contains spaces this causes errors for ffmpeg execution later.
    // specifically, in relating to input file name. They are separated by commas in the argument later...
    Directory appDocumentDir = await getApplicationDocumentsDirectory();
    String rawDocumentPath = appDocumentDir.path;

    //* TO-DO: instead of /output.mp3, make it something related to the new file later (like the name of the file)
    String outputPath = rawDocumentPath + "/checkagain.mp3";

    // print(rawDocumentPath + "\n" + outputPath);

    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });

    // Try to load audio from a source and catch any errors.
    try {

      String inPath = ""; // the input file path on-device

      // Call to open file manager on android and iOS. Choose only one file for now.
      // *TO-DO: add method to pick multiple files and create multiple output files.
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if(result != null) {
        PlatformFile file = result.files.first;

        inPath = file.path; // get the cached file

        // Display information about the file
        print(file.name);
        print(file.bytes);
        print(file.size);
        print(file.extension);
        print(file.path);
      } else {
        // User canceled the picker
        print("user cancelled the picker");
      }

      // Run FFmpeg on this single file and store it in app data folder
      final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
      String commandToExecute = "-i " + inPath + " " + outputPath;
      _flutterFFmpeg.execute(commandToExecute).then((rc) => print("FFmpeg process exited with rc $rc"));

      // Set the audio source given file input path
      // *TO-DO: for some reason the speed is automatically set to 1.5 unless you restart. Have to fix this.
      try {
        await _player.setAudioSource(AudioSource.uri(Uri.file(outputPath)),
          initialPosition: Duration.zero, preload: true);
      } catch (e) {
          // Catch load errors: 404, invalid url...
          print("Error loading audio source: $e");
        }
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
            StreamBuilder<double>(
              stream: player.speedStream,
              builder: (context, snapshot) => IconButton(
                icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showSliderDialog(
                    context: context,
                    title: "Adjust speed",
                    divisions: 10,
                    min: 0.5,
                    max: 1.5,
                    value: player.speed,
                    stream: player.speedStream,
                    onChanged: player.setSpeed,
                  );
                },
              ),
            ),
            // Text('Pitch', style: TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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
                SizedBox(width: 60),
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
            Icon(Icons.repeat, color: Colors.grey),
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
                SizedBox(width: 60),
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
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(padding: EdgeInsets.only(left: 15), child: Text('Speed')),
            Icon(Icons.dns, color: Colors.grey),
            Container(
                padding: EdgeInsets.only(right: 15), child: Text('Pitch')),
          ],
        )
      ],
    );
  }
}

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
