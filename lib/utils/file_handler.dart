import 'package:file_picker/file_picker.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musictranscriptiontools/models/library.dart';

// Try to load audio from a source and catch any errors.
Future<AudioFile?> selectFileForPlayer(String savePath) async {
  AudioFile? audioFile;
  try {
    String inPath = "";
    PlatformFile file; // the input file path on-device

    // Call to open file manager on android and iOS. Choose only one file for now.
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      file = result.files.first;

      inPath = file.path; // get the cached file

    } else {
      // User did not select a file, don't do anything.
      return null;
    }

    // Replace extension for savePath if not an mp3 file
    String ext = inPath.substring(inPath.lastIndexOf('.'));
    savePath = inPath.replaceAll(ext, ".mp3");

    audioFile = new AudioFile(
        file.name, "author", Duration(seconds: file.size), savePath);

    // Run FFmpeg on this single file and store it in app data folder
    final FlutterFFmpeg flutterFFmpeg = new FlutterFFmpeg();
    String commandToExecute =
        '-i ' + "\'" + inPath + "\'" + " " + "\'" + savePath + "\'";
    print("command to execute" + commandToExecute);
    flutterFFmpeg
        .execute(commandToExecute)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

    // Set the audio source given file input path
    //   await player.setAudioSource(AudioSource.uri(Uri.file(savePath)),
    //       initialPosition: Duration.zero, preload: true);
  } catch (e) {
    print("Error loading audio source: $e");
  }

  return audioFile;
}
