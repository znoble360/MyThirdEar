// @dart=2.9

import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:image/image.dart';
import 'package:musictranscriptiontools/wav_parser.dart';
import 'package:fft/fft.dart';

void main (List<String> args) {
  File fp = File(args[0]);

  Frequencies freq = Frequencies(fp);
  freq.generatePred(args[1]);
  freq.generateSpec(args[2]);
  //freq.printNotes();

}

class Frequencies {
  List notes = [];
  List<int> waveform;
  Image spec;
  List<List> res = [];

  final NUM_BINS = 2048;
  final SAMPLE_RATE = 44100;


  Frequencies(File fp) {
    waveform = Wav.binToList(fp);
    //waveform = Wav.waveform[0];
    //var temp = Wav(fp);
    //temp.printHeader();
    //print("length of waveform: " + waveform.length.toString());

    //var windowed = Window(new HammingWindowType).apply(waveform);
    //var fft = new FFT().Transform(windowed);



    // We want to sample enough to see eight notes at 300 bpm, or 10hz
    // so we will transform at least 2x that rate, which would be 20hz.
    // 20hz at an original sample rate of 44100hz is 2205 samples per transform
    // we need each frame at a power of 2, so in reality it would be 2048.

    // we also might try 100 hz for smoothness, but will have to see about how
    // well that runs. This would be 441 samples per transform, and closest 
    // power of 2 would be 512.

    // 2048 minimum transform size, maybe 512 transform for smoothness.
    // higher number means less transforms, less detail.

    final int transformSize = 2048;
    //final int transformSize = 512;

    int numFrames = (waveform.length/transformSize).toInt();

    spec = Image(NUM_BINS, numFrames);
    //spectrograph = Image(1440, numFrames);


    // make fft for every chunk of time
    for (int i = 0; i < numFrames; i++) {

      res.add([]);

      int start = i * transformSize;
      int end = (i+1) * transformSize;
      num max = 0;
      int maxIndex = 0;
      var fft = new FFT().Transform(waveform.sublist(start, end));

      if (fft.length != NUM_BINS) {
        print("uh oh, we have " + fft.length.toString() + " bins, not " + NUM_BINS.toString() + " bins");
      }

      // for each bin in the transform, compute the magnitude (aka modulus) 
      // of the complex result, then normalize
      for (int j = 0; j < NUM_BINS; j++) {
        num mag = fft[j].modulus;

        // find max for later
        if (mag > max) {
          max = mag;
          maxIndex = j;
        }
        res[i].add(mag);
      }
      //print("currentIndex:\t" + i.toString() + " of " + numFrames.toString());
      //print("maxIndex:\t" + maxIndex.toString());
      //print("estimated hz:\t" + _binToFreq(maxIndex).toString());
      //print("estimated note:\t" + noteToLetterName(_binToNote(maxIndex).round()));
      //print("");

      // normalize between 0 and 1 using max
      if (max == 0) {
        max = -1;
      }

      for (int j = 0; j < NUM_BINS; j++) {
        res[i][j] /= max;
      }

    }

    //TODO: add things to the image and predictions stuff, 

    // populate predictions for notes
    for (int i = 0; i < res.length; i++) {
      notes.add([]);

      num curNote = 0;
      num curSum = 0;
      int curNumBins = 0;

      // here we average the intensity of bins corresponding to
      // curNote-0.5 and curNote+0.5, then add these averages to
      // the corresponding notes index for our note intensity prediction
      for (int j = 0; j < res[0].length; j++) {

        // to catch when we have reached the boundary between
        // curNote and the next note
        if (j >= _noteToBin(curNote+0.5)) {

          double predIntensity = curSum / curNumBins;
          notes[i].add(predIntensity);

          curNote++;
          curSum = 0;
          curNumBins = 0;
        }

        curSum += res[i][j];
        curNumBins++;

      }
    }

    // populate the spectrograph image
    //print("numFrames:" + numFrames.toString());
    //print("NUM_BINS:" + NUM_BINS.toString());
    for (int i = 0; i < numFrames; i++) {
      for (int j = 0; j < NUM_BINS; j++) {

        //int color = _intensityToColor(res[i][j]);

        int colorR = 255;
        int colorG = 255;
        int colorB = 255;
        int r = (res[i][j] * colorR).toInt();
        int g = (res[i][j] * colorG).toInt();
        int b = (res[i][j] * colorB).toInt();

        //print(i.toString() + ", " + j.toString() + ", " + r.toString() + ", " + g.toString() + ", " + b.toString());
        spec.setPixelRgba(j, i, r, g, b);
      }
    }
  }

  void generateSpec(String outFileName) {
    File fp = new File(outFileName);
    fp.writeAsBytes(encodePng(spec));
  }

  void generatePred(String outFileName) {
    String csv = const ListToCsvConverter().convert(res);

    var out = new File(outFileName).openWrite();
    out.write(csv);
    out.close();
  }

  String noteToLetterName(int note) {
    int letter = note % 12;
    switch(letter) {
      case 0: {
        return "A";
      } break;

      case 1: {
        return "A#/Bb";
      } break;

      case 2: {
        return "B/Cb";
      } break;

      case 3: {
        return "C";
      } break;

      case 4: {
        return "C#/Db";
      } break;

      case 5: {
        return "D";
      } break;

      case 6: {
        return "D#/Eb";
      } break;

      case 7: {
        return "E";
      } break;

      case 8: {
        return "F";
      } break;

      case 9: {
        return "F#/Gb";
      } break;

      case 10: {
        return "G";
      } break;

      case 11: {
        return "G#/Ab";
      } break;

    }
  }

  // given a note, returns the corresponding frequency associated with it
  double _noteToFreq(double note) {
    return pow(2, (note/12) * 27.5);
  }

  // given frequency, returns the note value
  double _freqToNote(double freq) {
    // base conversion from ln to log_2
    double log_2 = log(freq/27.5) / ln2;
    return 12 * log_2;
  }

  // given a frequency, returns the closest bin associated with it
  double _freqToBin(double freq) {
    double binWidth = SAMPLE_RATE / NUM_BINS;
    double binIndex = freq / binWidth;

    return binIndex;
  }

  // given a binIndex, returns the frequency represented by that bin
  double _binToFreq(int binIndex) {
    double binWidth = SAMPLE_RATE / NUM_BINS;

    return binIndex * binWidth;
  }

  double _noteToBin(double note) {
    double freq = _noteToFreq(note);
    return _freqToBin(freq);
  }

  double _binToNote(int binIndex) {
    double freq = _binToFreq(binIndex);
    return _freqToNote(freq);
  }

  // given color intensity, returns grey scale rgb color
  // can be changed to something other than grey
  //Color _intensityToColor(double intensity) {
  //  int val = 255 * intensity;
  //  return Color.fromRgba(val, val, val, 255);
  //}
}
