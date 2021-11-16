import 'package:hive/hive.dart';

part 'audioFile.g.dart';

// AudioFileData model for the Hive DB, generates audioFile.g.dart by running: 
// flutter packages pub run build_runner build

@HiveType(typeId: 1)
class AudioFileData {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String author;

  @HiveField(2)
  final String filepath;

  @HiveField(3)
  final String waveformBinPath;

  AudioFileData({
    required this.name,
    required this.author,
    required this.filepath,
    required this.waveformBinPath
  });
}
