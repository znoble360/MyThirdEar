// @dart=2.9

import 'dart:io';
import 'dart:math';
import 'package:musictranscriptiontools/wav_parser.dart';
import 'package:fft/fft.dart';

void main (List<String> args) {
  File fp = File(args[0]);

  Frequencies freq = Frequencies(fp);
  //freq.printNotes();

}

class Frequencies {
  List<double> notes = List.filled(88, -1);
  List<int> waveform;
  List<double> pianoNotes;

  Frequencies(File fp){
    waveform = Wav(fp).waveform[0];
    //var temp = Wav(fp);
    //temp.printHeader();
    //print("length of waveform: " + waveform.length.toString());

    //var windowed = Window(new HammingWindowType).apply(waveform);
    //var fft = new FFT().Transform(windowed);

    
    var fft = new FFT().Transform(waveform.sublist(0, 4096));


    num max = 0;
    List res = [];

    for (int i = 0; i < numBins; i++) {
      res.add([]);
      for (int j = 0; j < 4096; j++) {
        num mag = sqrt(fft[j].real*fft[j].real + fft[j].imaginary*fft[j].imaginary);
        if (mag > max) {
          max = mag;
        }

        res[i].add(mag);
      }
    }

    for (int i = 0; i < numBins; i++) {
      for (int j = 0; j < 4096; j++) {
        if (j != 0) {
          stdout.write(",");
        }
        stdout.write(res[i][j]/max);
      }
    }

    //for (int i = 0; i < 2048; i++) {
    //  print(i.toString() + ":\t" + fft[i].real.toString());
    //  if (fft[i].real.abs() < 1000) {
    //    print(i.toString() + ":\t" + fft[i].real.toString());
    //  }
    //}
    //print(fft.length);

    //print(fft.toString());

  }
}
