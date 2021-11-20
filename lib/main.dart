// ignore_for_file: close_sinks

import 'dart:io';

import 'package:MyThirdEar/models/audioFile.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:MyThirdEar/screens/library.dart';
import 'package:MyThirdEar/models/library.dart';
import 'package:MyThirdEar/ui/home/theme.dart';
import 'package:rxdart/rxdart.dart';

Future<void> main() async {
  // Initialize Hive DB
  await Hive.initFlutter();

  // Register AudioFileData model
  Hive.registerAdapter(AudioFileDataAdapter());

  // Open Hive DB
  await Hive.openBox('audioFileData');

  final _appDocDir = await getApplicationDocumentsDirectory();

  runApp(MyApp(appDocDir: _appDocDir));
}

class MyApp extends StatelessWidget {
  final Directory appDocDir;
  MyApp({Key? key, required this.appDocDir}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<AudioFile> audioFiles = [];

    // Initialize 'audioFileData' Hive box
    final Box box = Hive.box('audioFileData');

    // Populate library model with the previous audiofiles we have stored in the Hive DB by looping through them
    for (int i = 0; i < box.length; i++) {
      var currentAudioFile = box.getAt(i);

    // get the full path to waveformBin file
    String applicationDirectory = currentAudioFile.waveformBinPath;
    String waveformBinPath = '${appDocDir.path}/$applicationDirectory';
    print((waveformBinPath));

      // Link the waveform file controller to the waveform bin path
      var waveformFileController = new BehaviorSubject<String>();
      waveformFileController.add(waveformBinPath);

      audioFiles.add(new AudioFile(
          currentAudioFile.name,
          currentAudioFile.author,
          currentAudioFile.filepath,
          waveformFileController,
          currentAudioFile.waveformBinPath));
    }

    return MultiProvider(
      providers: [Provider(create: (context) => LibraryModel(audioFiles))],
      child: MaterialApp(
        title: 'MyThirdEar',
        theme: ThemeUtils(context).themeData,
        initialRoute: '/',
        routes: {'/': (context) => const Library()},
      ),
    );
  }
}
