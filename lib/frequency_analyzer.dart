// @dart=2.9

import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:MyThirdEar/wav_parser.dart';
import 'package:fft/fft.dart';

//// Sample useage:
//void main () {
//
//  String soundFileName = "example.wav";
//  String outputFileName = "example.bin";
//
//  // takes the audio file at soundFileName
//  // creates a waveform bin file at outputFileName,
//  Wav.wavToBin(soundFileName, outputFileName);
//
//  File binFile = File(outputFileName);
//
//  // initialize an instance of Frequencies using the generated binFile
//  Frequencies freq = Frequencies(binFile);
//
//  // generates the predictions array csv at predOutputLocation
//  String predOutputLocation = "example.csv";
//  freq.generatePred(predOutputLocation);
//
//  // generates the spectrograph png at specOutputLocation
//  String specOutputLocation = "example.csv";
//  freq.generateSpec(specOutputLocation);
//
//  // Frequencies.noteToLetterName(n) can be used to convert numbers
//  // in the predictions array to their corresponding note letter strings
//  // this is printing the first note on the keyboard, which should be A.
//  print(Frequencies.noteToLetterName(0));
//
//  // this is printing the last note on the keyboard, which should be C
//  print(Frequencies.noteToLetterName(87));
//
//}

final int NUM_BINS = pow(2, 13);
final int SAMPLE_RATE = 44100;
final int NOTES_ON_KEYBOARD = 88;
final int TONAL_RESOLUTION_OF_SPEC = 11;

class Freq {
  String filename;
  String predictionPath;
  String specImagePath;

  Freq(this.filename, this.predictionPath, this.specImagePath);
}

Future<void> doFreq(
    String filename, String predictionPath, String specImagePath) async {
  print("Starting compute");
  Freq f = new Freq(filename, predictionPath, specImagePath);
  await compute(computeFreq, f);

  print("Ending Compute");
}

void computeFreq(Freq f) async {
  String outputFileName = f.filename;
  String predictionPath = f.predictionPath;
  String specImagePath = f.specImagePath;

  List<List> notes = [];
  List<List> spec_data = [];
  List<int> waveform;
  Image spec;
  List<List> res = [];

  File fp = File(outputFileName);

  waveform = Wav.binToList(fp);
  //waveform = Wav.waveform[0];
  //var temp = Wav(fp);
  //temp.printHeader();
  //print("length of waveform: " + waveform.length.toString());

  //var windowed = Window(new HammingWindowType).apply(waveform);
  //var fft = new FFT().Transform(windowed);

  final int transformSize = NUM_BINS;

  int numFrames = (waveform.length / transformSize).toInt();

  // make fft for every chunk of time
  for (int i = 0; i < numFrames; i++) {
    res.add([]);

    int start = i * transformSize;
    int end = (i + 1) * transformSize;
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
      if (j >= _noteToBin(curNote + 0.5)) {
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
      int noteStart = _noteToBin(j.toDouble() - 0.5).toInt();
      int noteEnd = _noteToBin(j.toDouble() + 0.5).toInt();

      // cut each note on the keyboard into TONAL_RESOLUTION_OF_SPEC slices
      // then loop through each slice
      for (int k = 0; k < TONAL_RESOLUTION_OF_SPEC; k++) {
        double curNoteChunkStart =
            j + (k.toDouble() / TONAL_RESOLUTION_OF_SPEC.toDouble());
        double curNoteChunkEnd =
            j + ((k + 1).toDouble() / TONAL_RESOLUTION_OF_SPEC.toDouble());
        int bin = _noteToBin(curNoteChunkStart).toInt();

        double curSum = 0;
        int curNumBins = 0;

        // for each slice, average the bins that pertain to that slice of the frame
        while (bin < _noteToBin(curNoteChunkEnd)) {
          curSum += res[i][bin];
          curNumBins++;
          bin++;
        }

        double avg = curSum / curNumBins.toDouble();

        spec_data[i].add(avg);
      }
    }
  }

  spec = _2dListToImage(spec_data);

  print("Predicting");
  // generates the predictions array csv at predOutputLocation
  generatePred(predictionPath, notes);

  print("Generating spec");
  // generates the spectrograph png at specOutputLocation
  generateSpec(specImagePath, spec);
}

// this will write an image of the spectrograph to given the output file name
void generateSpec(String outFileName, Image spec) {
  File fp = new File(outFileName);
  List<int> png = encodePng(spec);
  print("Encode png length = " + png.length.toString());
  fp.writeAsBytesSync(png);
  print("Writing spec to: " + outFileName);
  print("File length = " + fp.lengthSync().toString());
}

// this will write a csv of the predictions to given the output file name
// this csv will be in the form of:
//    each row is one frame of the sound file
//    each column is the predicted intensity of each note on the keyboard
// so if you import the .csv into a 2d list "csv",
// the predicted intensity of A0 in the first instance of the audio file
// would be csv[0][0].
// intensity of A1 at the 3rd frame would be csv[3][12] (A1 would be note 12)
void generatePred(String outFileName, List<List> notes) {
  String csv = const ListToCsvConverter().convert(notes);

  var out = new File(outFileName).openWrite();
  out.write(csv);
  out.close();
}

// given the number of a key on an 88 key keyboard,
// returns the note letter name associated with that keyboard key
String noteToLetterName(int note) {
  int letter = note % 12;
  switch (letter) {
    case 0:
      {
        return "A";
      }
      break;

    case 1:
      {
        return "A#/Bb";
      }
      break;

    case 2:
      {
        return "B/Cb";
      }
      break;

    case 3:
      {
        return "C";
      }
      break;

    case 4:
      {
        return "C#/Db";
      }
      break;

    case 5:
      {
        return "D";
      }
      break;

    case 6:
      {
        return "D#/Eb";
      }
      break;

    case 7:
      {
        return "E";
      }
      break;

    case 8:
      {
        return "F";
      }
      break;

    case 9:
      {
        return "F#/Gb";
      }
      break;

    case 10:
      {
        return "G";
      }
      break;

    case 11:
      {
        return "G#/Ab";
      }
      break;

    default:
      {
        return "error";
      }
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
  return pow(2, (note / 12)) * 27.5;
}

// given frequency, returns the note value
double _freqToNote(double freq) {
  // base conversion from ln to log_2
  double log_2 = log(freq / 27.5) / ln2;
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
