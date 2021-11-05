import 'dart:async';

import 'package:rxdart/rxdart.dart';

class LibraryModel {
  List<AudioFile> audioFiles = [];

  addAudioFile(AudioFile file) {
    audioFiles.add(file);
  }

  List<AudioFile> getAllAudioFiles() => audioFiles;
  int getLibraryLength() => audioFiles.length;

  LibraryModel(this.audioFiles);
}

class AudioFile {
  final String name;
  final String author;
  final Duration duration;
  final String filepath;
  final BehaviorSubject<String> waveformFileController;

  AudioFile(this.name, this.author, this.duration, this.filepath, this.waveformFileController);
}
