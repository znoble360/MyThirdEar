// @dart=2.9

import 'dart:io';
import 'dart:typed_data';

void main() {
  String fileName = '/home/znoble360/tones/soundfile.sapp.org_doc_WaveFormat.wav';
  File fp = File(fileName);

  Wav girlFromIpanema = Wav(fp);
  girlFromIpanema.printHeader();

}

class Wav {

  // Header variables
  int fileSize = -1;
  int subchunk1Size = -1;
  int audioFormat = -1;
  bool pcm;
  int numChannels = -1;
  int sampleRate = -1;
  int byteRate = -1;
  int bytesPerFrame = -1;
  int bitsPerSample = -1;
  int dataSize = -1;

  // wav byte data
  ByteData data;
  
  num numFrames = -1;

  List<List<int>> waveform;

  Wav(File fp) {

    Uint8List wav = fp.readAsBytesSync();

    ByteData header = ByteData.sublistView(wav, 0, 44);
    ByteData data = ByteData.sublistView(wav, 44);

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

    if (String.fromCharCodes(temp) != 'data')
    {
      print('warning: unexpected wav format "' + String.fromCharCodes(temp) + '"');
    }

    // SubChunk2Size
    dataSize = header.getUint32(40, Endian.little);
    
    // numFrames
    numFrames = dataSize / (bitsPerSample * numChannels);
    numFrames = numFrames.round();

    waveform = new List();
    for (int i = 0; i < numChannels; i++) {
      waveform.add(new List());
    }

    // waveform data
    print('');
    print('Data:');
    for (int i = 0; i < data.lengthInBytes; i++) {
      //print(data.getUint8(i));
    }

  }

  void printHeader(){
    print('fileSize:\t'        + this.fileSize.toString());
    print('subchunk1Size:\t'   + this.subchunk1Size.toString());
    print('audioFormat:\t'     + this.audioFormat.toString());
    print('pcm:\t\t'             + this.pcm.toString());
    print('numChannels:\t'     + this.numChannels.toString());
    print('sampleRate:\t'      + this.sampleRate.toString());
    print('byteRate:\t'        + this.byteRate.toString());
    print('bytesPerFrame:\t'   + this.bytesPerFrame.toString());
    print('bitsPerSample:\t'   + this.bitsPerSample.toString());
    print('dataSize:\t'        + this.dataSize.toString());

  }
}
