// @dart=2.9

import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:image/image.dart';
import 'package:musictranscriptiontools/wav_parser.dart';
import 'package:fft/fft.dart';

// Sample useage:
//void main (List<String> args) {
//
//  // args are: 
//  // 1) input bin
//  // 2) csv output name
//  // 3) png output name
//  File fp = File(args[0]);
//
//  Frequencies freq = Frequencies(fp);
//  freq.generatePred(args[1]);
//  freq.generateSpec(args[2]);
//  //freq.printNotes();
//
//}

class Frequencies {
  List<List> notes = [];
  List<List> spec_data = [];
  List<int> waveform;
  Image spec;
  List<List> res = [];

  final int NUM_BINS = pow(2, 13);
  final int SAMPLE_RATE = 44100;
  final int NOTES_ON_KEYBOARD = 88;
  final int TONAL_RESOLUTION_OF_SPEC = 11;


  Frequencies(File fp) {
    waveform = Wav.binToList(fp);
    //waveform = Wav.waveform[0];
    //var temp = Wav(fp);
    //temp.printHeader();
    //print("length of waveform: " + waveform.length.toString());

    //var windowed = Window(new HammingWindowType).apply(waveform);
    //var fft = new FFT().Transform(windowed);

    final int transformSize = NUM_BINS;

    int numFrames = (waveform.length/transformSize).toInt();

    // make fft for every chunk of time
    for (int i = 0; i < numFrames; i++) {

      res.add([]);

      int start = i * transformSize;
      int end = (i+1) * transformSize;
      num max = 0;
      int maxIndex = 0;
      var fft = new FFT().Transform(waveform.sublist(start, end));

      if (fft.length != NUM_BINS) {
        print("uh oh, we have " + 
            fft.length.toString() + 
            " bins, not " + 
            NUM_BINS.toString() + 
            " bins");
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

      // normalize between 0 and 1 using max
      if (max == 0) {
        max = -1;
      }

      for (int j = 0; j < NUM_BINS; j++) {
        res[i][j] /= max;
      }

    }

    // populate predictions for notes
    for (int i = 0; i < res.length; i++) {
      notes.add([]);

      num curNote = 0;
      num curSum = 0;
      int curNumBins = 0;

      // here we average the intensity of bins corresponding to
      // curNote-0.5 and curNote+0.5, then add these averages to
      // the corresponding notes index for our note intensity prediction
      // starting at a quartertone below the lowest note on a keyboard
      // up to the highest note on the keyboard
      if (_noteToBin(88).round() > res[0].length) {
        print("error: not enough fft bins for whole keyboard");
      }
      int top = _noteToBin(NOTES_ON_KEYBOARD.toDouble()).round();
      for (int j = _noteToBin(-0.5).toInt(); j < top; j++) {

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


    // generate data for spectrograph, scaling logarithmically
    // loop through each frame of res
    for (int i = 0; i < res.length; i++) {
      spec_data.add([]);

      // loop through each note on the keyboard
      for (int j = 0; j < NOTES_ON_KEYBOARD; j++) {
        int noteStart = _noteToBin(j.toDouble()-0.5).toInt();
        int noteEnd = _noteToBin(j.toDouble()+0.5).toInt();

        // cut each note on the keyboard into TONAL_RESOLUTION_OF_SPEC slices
        // then loop through each slice
        for (int k = 0; k < TONAL_RESOLUTION_OF_SPEC; k++) {

          double curNoteChunkStart =
              j + (k.toDouble()/TONAL_RESOLUTION_OF_SPEC.toDouble());
          double curNoteChunkEnd =
              j + ((k+1).toDouble()/TONAL_RESOLUTION_OF_SPEC.toDouble()); 
          int bin = _noteToBin(curNoteChunkStart).toInt();

          double curSum = 0;
          int curNumBins = 0;

          // for each slice, average the bins that pertain to that slice of the frame
          while (bin < _noteToBin(curNoteChunkEnd)) {
            curSum += res[i][bin];
            curNumBins++;
            bin++;
          }

          double avg = curSum/curNumBins.toDouble();

          spec_data[i].add(avg);

        }
      }
    }

    spec = _2dListToImage(spec_data);
  }

  // this will write an image of the spectrograph to given the output file name
  void generateSpec(String outFileName) {
    File fp = new File(outFileName);
    fp.writeAsBytes(encodePng(spec));
  }

  // this will write a csv of the predictions to given the output file name
  void generatePred(String outFileName) {
    String csv = const ListToCsvConverter().convert(notes);

    var out = new File(outFileName).openWrite();
    out.write(csv);
    out.close();
  }

  // given the number of a key on an 88 key keyboard,
  // returns the note letter name associated with that keyboard key
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

  // populates an image given a 2d array of intensity values
  Image _2dListToImage(List list) {

    Image img = Image(list[0].length, list.length);

    for (int i = 0; i < img.height; i++) {
      for (int j = 0; j < img.width; j++) {

        int colorR = 255;
        int colorG = 255;
        int colorB = 255;
        int r = (list[i][j] * colorR).toInt();
        int g = (list[i][j] * colorG).toInt();
        int b = (list[i][j] * colorB).toInt();

        img.setPixelRgba(j, i, r, g, b);
      }
    }

    return img;
  }

  // given a note, returns the corresponding frequency associated with it
  double _noteToFreq(double note) {
    return pow(2, (note/12)) * 27.5;
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
}
