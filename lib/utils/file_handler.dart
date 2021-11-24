import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:musictranscriptiontools/models/library.dart';
import 'package:rxdart/rxdart.dart';

// Try to load audio from a source and catch any errors.
Future<AudioFile?> selectFileForPlayer(Directory appDocDir) async {
  AudioFile? audioFile;
  try {
    PlatformFile file; // the input file path on-device
    final waveformFileController = BehaviorSubject<String>();

    // Call to open file manager on android and iOS. Choose only one file for now.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result == null) {
      // User did not select a file, don't do anything.
      return new AudioFile("", "", "", waveformFileController, "");
    }

    file = result.files.first;

    String md5Hash = _generateMD5Hash(file);
    final Directory newDirectory = Directory('${appDocDir.path}/$md5Hash');
    if (await newDirectory.exists()) {
      // Directory already exists, meaning that we already dealt with this song before.
      // TODO: Check that the files we expect to have exist.
      String audioMP3Path = '${newDirectory.path}/audio.mp3';

      print("We've already seen this file, look at cached files");

      return null;
    }

    // Create directory since it doesn't exist yet.
    final Directory finalDirectory = await newDirectory.create(recursive: true);
    final String dirPath = finalDirectory.path;

    String audioMP3Path = '$dirPath/audio.mp3';
    String audioWAVpath = '$dirPath/songWAV.wav'; // path to song's wav
    String bookmarksPath = '$dirPath/bookmarks.json'; // path to bookmarks file
    String waveformBinPath = '$dirPath/waveform.bin';
    String infoJSONPath = '$dirPath/info.json';

    // Run FFmpeg on this single file and store it in app data folder
    String convertToMp3Command = '-i "${file.path}" $audioMP3Path';
    FFmpegKit.executeAsync(convertToMp3Command, (session) async {
      await session.getReturnCode();
    });

    // Generate waveform binary data.
    String generateWaveformBinDataCmd =
        '-i "${file.path}" -v quiet -ac 1 -filter:a aresample=1000 -map 0:a -c:a pcm_s16le -f data $waveformBinPath';

    print(generateWaveformBinDataCmd);

    FFmpegKit.executeAsync(generateWaveformBinDataCmd, (session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        waveformFileController.add(waveformBinPath);
      } else {
        print("Error generating waveform file controller");
      }
    });

    // Convert to WAV
    String convertToWavCommand = '-i "${file.path}" $audioWAVpath';
    FFmpegKit.executeAsync(convertToWavCommand, (session) async {
      await session.getReturnCode();
    });

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
    if (await songInfo.exists()) {
      print("say that the songInfo file exists");
      String fileContent = await songInfo.readAsString();
      print("file content: " + fileContent);
    } else {
      print("error");
    }

    print("mp3 command: " + convertToMp3Command);

    String relativeAudioMP3Path = '$md5Hash/audio.mp3';
    String relativeWaveformBinPath = '$md5Hash/waveform.bin';

    audioFile = new AudioFile(file.name, "author", relativeAudioMP3Path,
        waveformFileController, relativeWaveformBinPath);
  } catch (e) {
    print("Error loading audio source: $e");
  }

  return audioFile;
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
