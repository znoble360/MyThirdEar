// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audioFile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioFileDataAdapter extends TypeAdapter<AudioFileData> {
  @override
  final int typeId = 1;

  @override
  AudioFileData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioFileData(
      name: fields[0] as String,
      author: fields[1] as String,
      filepath: fields[2] as String,
      waveformBinPath: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AudioFileData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.author)
      ..writeByte(2)
      ..write(obj.filepath)
      ..writeByte(3)
      ..write(obj.waveformBinPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioFileDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
