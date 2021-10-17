import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:just_audio/just_audio.dart';

// Try to load audio from a source and catch any errors.
void selectFileForPlayer(AudioPlayer player, Directory appDocDir) async {
  try {
    // Call to open file manager on android and iOS. Choose only one file for now.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result == null) {
      // User did not select a file, don't do anything.
      return;
    }

    PlatformFile file = result.files.first;

    String md5Hash = _generateMD5Hash(file);
    final Directory newDirectory = Directory('${appDocDir.path}/$md5Hash');
    if (await newDirectory.exists()) {
      // Directory already exists, meaning that we already dealt with this song before.
      // TODO: Check that the files we expect to have exist.
      String audioMP3Path = '${newDirectory.path}/audio.mp3';

      print("We've already seen this file, look at cached files");

      // Set the audio source given file input path
      await player.setAudioSource(AudioSource.uri(Uri.file(audioMP3Path)),
          initialPosition: Duration.zero, preload: true);

      return;
    }

    // Create directory since it doesn't exist yet.
    final Directory finalDirectory = await newDirectory.create(recursive: true);
    final String dirPath = finalDirectory.path;

    String audioMP3Path = '$dirPath/audio.mp3';
    // TODO: Generate waveform data and save it to waveform.bin
    // String waveformBinPath = '$dirPath/waveform.bin';

    // Run FFmpeg on this single file and store it in app data folder
    final FlutterFFmpeg flutterFFmpeg = new FlutterFFmpeg();
    String convertToMp3Command = '-i ${file.path} $audioMP3Path';

    flutterFFmpeg
        .execute(convertToMp3Command)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

    // Set the audio source given file input path
    await player.setAudioSource(AudioSource.uri(Uri.file(audioMP3Path)),
        initialPosition: Duration.zero, preload: true);
  } catch (e) {
    print("Error loading audio source: $e");
  }
}

String _generateMD5Hash(PlatformFile file) {
  if (file.bytes == null) {
    return "";
  }

  return md5.convert(file.bytes!).toString();
}
