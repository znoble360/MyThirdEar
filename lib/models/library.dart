import 'package:rxdart/rxdart.dart';

// Model representing the list of audio files displayed to a user in the home page
class LibraryModel {
  List<AudioFile> audioFiles = [];

  addAudioFile(AudioFile file) {
    audioFiles.add(file);
  }

  deleteAudioFile(AudioFile file) {
    audioFiles.remove(file);
  }

  List<AudioFile> getAllAudioFiles() => audioFiles;
  int getLibraryLength() => audioFiles.length;

  LibraryModel(this.audioFiles);
}

// Audio file model used to store metadata of the files in the user's library
class AudioFile {
  final String name;
  final String author;
  final String filepath;
  final String waveformBinPath;
  final String spectrogramPath;
  final String predictionPath;
  final BehaviorSubject<String> waveformFileController;

  AudioFile(this.name, this.author, this.filepath, this.waveformFileController,
      this.waveformBinPath, this.spectrogramPath, this.predictionPath);
}
