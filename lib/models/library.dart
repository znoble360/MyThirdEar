import 'dart:io';
import 'dart:isolate';

import 'package:MyThirdEar/frequency_analyzer.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
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
  String hash = "temp";
  String originalPath = "";
  bool predictionFinished = true;

  AudioFile(this.name, this.author, this.filepath, this.waveformFileController,
      this.waveformBinPath, this.spectrogramPath, this.predictionPath);

  void runPrediction(Directory appDocDir) async {
    String absFilePath = "${appDocDir.path}/$filepath";
    String absPredictionPath = "${appDocDir.path}/$predictionPath";
    String absSpectrogramPath = "${appDocDir.path}/$spectrogramPath";
    String tempPredictionPath = "${appDocDir.path}/$hash/prediction.bin";

    print("Abs file path = " + absFilePath);
    print("Temp prediction path = " + tempPredictionPath);

    String generatePredictionBinCmd =
        '-i "$absFilePath" -v quiet -ac 1 -filter:a aresample=44100 -map 0:a -c:a pcm_s16le -f data "$tempPredictionPath"';

    // Run FFmpeg on this single file and store it in app data folder
    String convertToMp3Command =
        '-i "${this.originalPath}" -acodec libmp3lame $absFilePath';

    await FFmpegKit.executeAsync(convertToMp3Command, (session) async {
      final ReturnCode? returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print("Generate prediction bin: = " + generatePredictionBinCmd);

        await FFmpegKit.executeAsync(generatePredictionBinCmd, (session) async {
          print("Trying to predict note");
          final ReturnCode? returnCode = await session.getReturnCode();

          if (!ReturnCode.isSuccess(returnCode)) {
            print("Error generating prediction bin");
            String? logs = await session.getOutput();
            print("Return code = " + returnCode.toString());
            print(logs);
          }

          if (ReturnCode.isSuccess(returnCode)) {
            _processNotePrediction(absFilePath, tempPredictionPath,
                absSpectrogramPath, absPredictionPath);
          }
        });
      }
    });
  }

  _processNotePrediction(String audioFileName, String outputFileName,
      String specImagePath, String predictionPath) async {
    print("Making bin file");

    print("Initializing freqs");
    // initialize an instance of Frequencies using the generated binFile
    await doFreq(outputFileName, predictionPath, specImagePath);

    print("Prediction path = " + predictionPath);
    print("Spec Image path = " + specImagePath);

    this.predictionFinished = true;
  }
}
