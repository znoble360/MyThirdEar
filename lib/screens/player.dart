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

import 'package:prompt_dialog/prompt_dialog.dart';
import 'dart:io';
import 'dart:convert';

class MusicPlayer extends StatefulWidget {
  final AudioFile audioFile;
  MusicPlayerScreenState musicPlayerScreenState;
  MusicPlayer({required this.audioFile, required this.musicPlayerScreenState});

  @override
  _MusicPlayerPlayState createState() => _MusicPlayerPlayState();
}

class _MusicPlayerPlayState extends State<MusicPlayer>
    with WidgetsBindingObserver {
  late AudioPlayer _player;
  var _audioFile;
  var _appDocDir;
  var loopingMode;
  late Duration loopingStart;
  late Duration loopingEnd;
  var loopingError;

  var response;

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

  /* Kevin's methods */
  // Call to store the durations and name as a loop.
  void saveLoop(Duration start, Duration end, String res) {

    // Integers are easier to work with
    int starting = start.inSeconds;
    int ending = end.inSeconds;

    // Get the filepath for the json file
    var jsonPath = _audioFile.filepath.substring(
        0, _audioFile.filepath.length - 10)+'/info.json';
    var fullPath = '${_appDocDir.path}/$jsonPath';

    // Decode the json encoded object
    var parsedJson = jsonDecode(File(fullPath.toString()).readAsStringSync().toString()); // with decoding

    // Add the saved loop if it doesn't exist.
    if(parsedJson['$res'] == null){
      parsedJson['$res'] = 'start: ${starting.toString()},\n end: ${ending.toString()}';
      print('added this saved loop: ' + parsedJson['$res']);
    } else{
      print('a saved loop exists with that name...');
    }

    // Encode the new json data and write to the file
    String updateJson = jsonEncode(parsedJson);
    File(fullPath.toString()).writeAsString(updateJson);

    // Set the state to play that loop
    setState(() {
      loopingMode = "saved loop";
    });
  }

  // Deletes the saved loop from the JSON file (stored loops)
  void deleteLoop(String entry){

    // Decode the json file
    var jsonPath = _audioFile.filepath.substring(0, _audioFile.filepath.length - 10)+'/info.json';
    var fullPath = '${_appDocDir.path}/$jsonPath';
    var parsedJson = jsonDecode(File(fullPath.toString()).readAsStringSync().toString()); // with decoding

    // Check if the saved loop exists. If so, delete it. Else there was an error.
    if(parsedJson[entry] != null){
      parsedJson.remove(entry);
    } else {
      print('there was an error deleting that file'); // does not exist or some other error
    }

    // Encode the updated JSON data and write it to the file
    String updateJson = jsonEncode(parsedJson);
    File(fullPath.toString()).writeAsStringSync(updateJson);
  }

  // Read saved loop from the json file to return to the user.
  Map<String, String> getLoops(){

    // Get JSON file path and decode the data -- could probably refactor this.
    var jsonPath = _audioFile.filepath.substring(
        0, _audioFile.filepath.length - 10)+'/info.json';
    var fullPath = '${_appDocDir.path}/$jsonPath';
    var parsedJson = jsonDecode(File(fullPath.toString()).readAsStringSync().toString());

    // Returned map containing saved loop from the JSON file
    Map<String, String> newMap = new Map<String,String>(); // need to return this map...
    parsedJson.forEach((k,v) => addToMap(newMap, k, v));

    return newMap;
  }

  // Add saved loop to a map to use in the player. Ignore the 'name' object.
  void addToMap(Map<String,String> map, String k, String v){
    if(k != 'name') {
      map.putIfAbsent(k, () => v);
    }
  }

  // Display the saved loops in a dialog. A user can click on a saved loop, triggering the player to loop on that duration.
  // Alternatively, the user can delete an audio file by clicking the trash icon.
  void displayLoops(Map<String, String> map){

    // If there are no saved loops available, tell the user.
    if(map.isEmpty){
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Loops Saved'),
            content: SingleChildScrollView(
              child: ListBody(
                  children: <Widget> [ // maybe button
                    TextButton(
                        child: Text('Return'), // return to the player.
                        onPressed: () {
                          Navigator.pop(context);
                        }
                    )
                  ]
              ),
            ),
          )
      );
    } else { // saved loops exist.
      showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: const Text('Choose Loop'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[ // maybe button
                      for(var i in map.entries)
                        Row(
                            children: [
                              Row(
                                children: [
                                  TextButton(
                                    child: Text(i.key.toString()),
                                    // When clicked. Get the object and its durations to set the audio player.
                                    onPressed: () {
                                      String s = i.value.toString();
                                      String st = s.substring(
                                          s.indexOf(':') + 2, s.indexOf(','));
                                      String en = s.substring(
                                          s.lastIndexOf(':') + 2);

                                      // Set the state to that loop.
                                      setState(() {
                                        loopingMode = "saved loop";
                                      });
                                      _player.setClip(start: Duration(
                                          seconds: int.parse(st)),
                                          end: Duration(
                                              seconds: int.parse(en)));
                                      _player.setLoopMode(LoopMode.one);

                                      // Exit the dialog.
                                      Navigator.pop(
                                          context);
                                    },
                                  ),
                                  IconButton(
                                    onPressed: () {

                                      // Delete this saved loop.
                                      deleteLoop(i.key.toString());

                                      // Retrieve saved loops and display them or exit the dialog.
                                      Map<String, String> loops = getLoops();
                                      if(loops.isNotEmpty){
                                        displayLoops(loops);
                                      } else{
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: Icon(Icons.delete_forever),
                                  ),
                                ],
                              ),
                            ]
                        )
                    ],
                  ),
                ),
              )
      );
    }
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
                        stream: widget
                            .musicPlayerScreenState.waveformConfig.positionDataStream,
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
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      // Open saved loops.
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20)),
                                        onPressed: () {
                                          // Retrieve and display saved loops.
                                          Map<String, String> loops = getLoops();
                                          displayLoops(loops);
                                        },
                                        child: const Text('Loops'),
                                      ),
                                      // Create a new loop
                                      TextButton.icon(
                                          onPressed: () => setStartLoop(),
                                          icon: Icon(Icons.loop_outlined),
                                          label: Text("Start Loop")
                                      ),
                                    ]
                                )
                            // child: TextButton.icon(
                            //     onPressed: () => setStartLoop(),
                            //     icon: Icon(Icons.loop_outlined),
                            //     label: Text("Start Loop")
                            // ),
                            )
                        ),
                      if (loopingMode == "start")
                        Container(
                            child: Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                    onPressed: () => setEndLoop(),
                                    icon: Icon(Icons.loop_outlined),
                                    label: Text("End Loop")))),
                      if (loopingMode == "looping")
                      /// new: container, alignment in center, column to clear or save
                        Container(
                            child: Align(
                                alignment: Alignment.center,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                          onPressed: () => clearLoop(),
                                          icon: Icon(Icons.cancel_outlined),
                                          label: Text("Clear Loop")
                                      ),
                                      // User provides a name to save the loop.
                                      TextButton.icon(
                                        /// TO DO: May have to use a try catch if the user doesn't enter a name
                                          onPressed: () async{
                                            response = await prompt(context);
                                            print(response);
                                            if(response == null){
                                              // do nothing
                                            } else {
                                              saveLoop(loopingStart, loopingEnd, response);
                                            }
                                          },
                                          icon:Icon(Icons.check),
                                          label: Text("Save Loop"))
                                    ]
                                )
                            )
                        ),
                      // User is currently playing a saved loop. They have the option to return to the full song.
                      if(loopingMode == "saved loop")
                        Container(
                            child: Align(
                                alignment: Alignment.center,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    // alignment: Alignment.center,
                                    children: [
                                      TextButton.icon(
                                          onPressed: () => clearLoop(),
                                          icon: Icon(Icons.restart_alt_rounded),
                                          label: Text("Return")
                                      ),
                                    ]
                                )
                            )
                        ),
                      // if (loopingMode == "looping")
                      //   Container(
                      //       child: Align(
                      //           alignment: Alignment.center,
                      //           child: TextButton.icon(
                      //               onPressed: () => clearLoop(),
                      //               icon: Icon(Icons.cancel_outlined),
                      //               label: Text("Clear Loop")))),
                      ControlButtons(_player),
                    ],
                  )
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
