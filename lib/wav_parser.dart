// @dart=2.9

import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

//final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();


//void main() {
//  String fileName = '/home/znoble360/tones/soundfile.sapp.org_doc_WaveFormat.wav';
//  File fp = File(fileName);
//
//  Wav song = Wav(fp);
//  song.printHeader();
//  song.printData();
//  print(song.waveform[0].toString());
//
//}

//void main() {
//  String inputFileName = '/home/znoble360/tones/soundfile.sapp.org_doc_WaveFormat.wav';
//  String outputFileName = 'lib/wav44_1khz.bin';
//
//  Wav.wavToBin(inputFileName, outputFileName);
//
//  File fp = File(outputFileName);
//
//  List<int> result = Wav.binToList(fp);
//
//  print(result.toString());
//
//
//
//  
//}



// TODO: add section to skip subchunks that aren't RIFF, fmt, or data subchunks

// important variable to retrieve: waveform has all the audio data in a channel
// by channel 2D-list
class Wav {

  // Header variables
  int fileSize = -1;
  int subchunk1Size = -1;
  int audioFormat = -1;
  bool pcm = false;
  int numChannels = -1;
  int sampleRate = -1;
  int byteRate = -1;
  int bytesPerFrame = -1;
  int bitsPerSample = -1;
  int dataSize = -1;
  int dataStart = 44;

  // wav byte data
  ByteData data;
  
  num numFrames = -1;

  List<List<int>> waveform;

  Wav(File fp) {

    Uint8List wav = fp.readAsBytesSync();

    ByteData header = ByteData.sublistView(wav, 0, dataStart);
    ByteData data = ByteData.sublistView(wav, dataStart);

    // ----------------RIFF chunk descriptor----------------
    // ChunkID: "RIFF"
    List<int> temp = [];
    for (int i = 0; i < 4; i++) {
      temp.add(header.getUint8(i));
    }

    // ChunkSize: 36 + SubChunk2Size
    fileSize = header.getUint32(4, Endian.little);

    // Format: "WAVE"
    temp = [];
    for (int i = 8; i < 12; i++) {
      temp.add(header.getUint8(i));
    }

    // ----------------fmt subchunk----------------
    // SubChunk1ID: "fmt "
    temp = [];
    for (int i = 12; i < 16; i++) {
      temp.add(header.getUint8(i));
    }

    // SubChunk1Size
    subchunk1Size = header.getUint32(16, Endian.little);

    // AudioFormat (2 bytes)
    audioFormat = header.getUint16(20, Endian.little);
    if (audioFormat == 1) {
      pcm = true;
    }
    else {
      pcm = false;
    }

    // NumChannels (2 bytes)
    numChannels = header.getUint16(22, Endian.little);

    // SampleRate
    sampleRate = header.getUint32(24, Endian.little);

    // ByteRate
    byteRate = header.getUint32(28, Endian.little);

    // BlockAlign (2 bytes)
    bytesPerFrame = header.getUint16(32, Endian.little);

    // BitsPerSample (2 bytes)
    bitsPerSample = header.getUint16(34, Endian.little);

    // ----------------data subchunk----------------
    // SubChunk2ID (data)
    temp = [];

    for (int i = 36; i < 40; i++) {
      temp.add(header.getUint8(i));
    }

    if (String.fromCharCodes(temp) != 'data') {
      print('warning: unexpected wav format "' + String.fromCharCodes(temp) + '"');
      throw("Unexpected wav format");
    }

    // SubChunk2Size
    dataSize = header.getUint32(40, Endian.little);
    
    // numFrames
    numFrames = dataSize / (bitsPerSample * numChannels);
    numFrames = numFrames.round();

    // initialize waveform
    waveform = new List();
    for (int i = 0; i < numChannels; i++) {
      waveform.add(new List());
    }

    var intView = _dataToList(wav, dataStart, bitsPerSample);

    // stores samples into waveform array
    for (int i = 0; i < numChannels; i++) {
      for (int j = 0; j < numFrames; j++) {
        if (i+j*numChannels < intView.length) {
          waveform[i].add(intView[i+j*numChannels]);
        }
      }
    }
  }

  static void wavToBin(String inputFileName, String outputFileName) {

    String toBinCommand = "ffmpeg -y -i " + inputFileName + " -ar 44100 -ac 1 -map 0:a -c:a pcm_s16le -f data " + outputFileName;

    await FFmpegKit.executeAsync(toBinCommand);

  }

  static List<int> binToList(File fp) {

    Uint8List bin = fp.readAsBytesSync();
    Int16List temp = Int16List.view(bin.buffer);
    return temp.toList();
  }

  void printHeader() {
    print('Header information:');
    print('fileSize:\t'         + this.fileSize.toString());
    print('subchunk1Size:\t'    + this.subchunk1Size.toString());
    print('audioFormat:\t'      + this.audioFormat.toString());
    print('pcm:\t\t'            + this.pcm.toString());
    print('numChannels:\t'      + this.numChannels.toString());
    print('sampleRate:\t'       + this.sampleRate.toString());
    print('byteRate:\t'         + this.byteRate.toString());
    print('bytesPerFrame:\t'    + this.bytesPerFrame.toString());
    print('bitsPerSample:\t'    + this.bitsPerSample.toString());
    print('dataSize:\t'         + this.dataSize.toString());
    print('');

  }

  void printData() {
    print('Samples by channel:');
    for (int i = 0; i < waveform.length; i++) {
      print(waveform[i].toString());
    }
    print('');
  }

  _dataToList(Uint8List wav, int byteOffset, int sampleBitSize){
    switch (sampleBitSize) {
      case 8:
        return Uint8List.sublistView(wav, byteOffset);
      case 16:
        return Int16List.sublistView(wav, byteOffset);
      case 24:
        throw Exception("24-bit audio not yet supported");
      case 32:
        return Int32List.sublistView(wav, byteOffset);
      case 64:
        return Int64List.sublistView(wav, byteOffset);
      default:
        throw Exception("Unexpected sample bit size");
    }
  }
}
