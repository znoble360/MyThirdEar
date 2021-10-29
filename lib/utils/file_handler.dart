import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

// Try to load audio from a source and catch any errors.
// void selectFileForPlayer(AudioPlayer player, String savePath) async {
void selectFileForPlayer(AudioPlayer player, Directory appDocDir) async {
  try {
    // String inPath = ""; // the input file path on-device

    // Call to open file manager on android and iOS. Choose only one file for now.
    // FilePickerResult? result = await FilePicker.platform.pickFiles();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    // if (result != null) {
    //   PlatformFile file = result.files.first;
    //
    //   inPath = file.path; // get the cached file
    // } else {
    //   // User did not select a file, don't do anything.
    //   return;
    // }
    if(result == null){
      return;
    }

    // // Replace extension for savePath if not an mp3 file
    // String ext = inPath.substring(inPath.lastIndexOf('.'));
    // savePath = inPath.replaceAll(ext, ".mp3");

    PlatformFile file = result.files.first;

    // Hash the filename and create a new folder with the hashed file
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

    // To store file information
    String audioMP3Path = '$dirPath/songMP3.mp3'; // path to the song's mp3
    String audioWAVpath = '$dirPath/songWAV.wav'; // path to song's wav
    String bookmarksPath = '$dirPath/bookmarks.json'; // path to bookmarks file
    String wavBinPath = '$dirPath/wav.bin';
    String infoJSONPath = '$dirPath/info.json';

    /* Here is where we would do the processing */
    /* how to write and write/to JSON file: https://www.youtube.com/watch?v=oZNvRd96iIs&ab_channel=TheFlutterFactory */
    // Store the song name in an info.json file with the path above.
    String ext = file.name.substring(file.name.lastIndexOf('.'));
    String songName = file.name.replaceAll(ext, "");
    Song song = Song(songName); // create new song to be serialized
    String songJSON = jsonEncode(song);
    print('making the JSON, should show file name: ');
    print(songJSON);
    File songInfo = File('$infoJSONPath');
    await songInfo.writeAsString(songJSON);
    if(await songInfo.exists()){
      print("say that the songInfo file exists");
      String fileContent = await songInfo.readAsString();
      print("file content: " + fileContent);
    } else{
      print("error");
    }

    // // Run FFmpeg on this single file and store it in app data folder

    // TODO: Might want to check if it's an mp3 already before running the change.
    final FlutterFFmpeg flutterFFmpeg = new FlutterFFmpeg();
    // String commandToExecute = '-i ' + "\'"+ inPath + "\'" + " " + "\'"+savePath+"\'";
    // print("command to execute" + commandToExecute);

    /* Convert to mp3 */
    String convertToMp3Command = '-i ${file.path} $audioMP3Path';
    print("mp3 command: " + convertToMp3Command);

    print('CONVERTING TO MP3');
    await flutterFFmpeg
        // .execute(commandToExecute)
        .execute(convertToMp3Command)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

    /* Convert to wav */
    String convertToWavCommand = '-i ${file.path} $audioWAVpath';
    print('wav command: ' + convertToWavCommand);

    print('CONVERTING TO WAV');
    await flutterFFmpeg
    // .execute(commandToExecute)
        .execute(convertToWavCommand)
        .then((rc) => print("FFmpeg process exited with rc $rc"));

    // Set the audio source given file input path
    // await player.setAudioSource(AudioSource.uri(Uri.file(savePath)),
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

class Song {
  String name;

  Song(this.name);

  Map toJson() => {
    'name': name,
  };
}