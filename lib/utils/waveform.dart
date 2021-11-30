/*
Source: https://github.com/mattetti/waveform_demo
*/

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

const int WAVEFORM_SAMPLES_PER_SECOND = 1000;
const int SECONDS_IN_DISPLAY = 5;
const int SAMPLES_IN_DISPLAY = WAVEFORM_SAMPLES_PER_SECOND * SECONDS_IN_DISPLAY;

Future<WaveformData> loadWaveformData(String filename) async {
  Uri myUri = Uri.parse(filename);
  File audioFile = new File.fromUri(myUri);
  final data = ByteData.sublistView(await audioFile.readAsBytes());
  final List<int> array = [];

  for (int i = 0; i < data.lengthInBytes; i += 2) {
    array.add(data.getInt16(i, Endian.little));
  }

  return WaveformData.fromList(array);
}

class WaveformData {
  // bit depth of the data
  int bits;
  // the number of frames contained in the data
  int length;
  // data is in frames with min and max values for each sampled data point.
  List<int> data;
  List<double> _scaledData = [];

  WaveformData({
    required this.bits,
    required this.length,
    required this.data,
  });

  List<double> scaledData() {
    if (!_isDataScaled()) {
      _scaleData();
    }
    return _scaledData;
  }

  factory WaveformData.fromList(List<int> list) {
    return new WaveformData(bits: 16, length: list.length, data: list);
  }

  // get the frame position at a specific percent of the waveform. Can use a 0-1 or 0-100 range.
  int frameIdxFromPercent(double percent, int firstFrame, int lastFrame) {
    // if the scale is 0-1.0
    if (percent < 0.0) {
      percent = 0.0;
    } else if (percent > 1.0) {
      percent = 1.0;
    }

    int length = lastFrame - firstFrame;
    int idx = (length * percent).floor() + firstFrame;

    return idx;
  }

  Path path(Size size, double percent, double startPercent, double endPercent) {
    if (!_isDataScaled()) {
      _scaleData();
    }

    int firstFrame = frameIdxFromPercent(startPercent, 0, data.length);
    int lastFrame = frameIdxFromPercent(endPercent, 0, data.length);

    int middleFrame = frameIdxFromPercent(percent, firstFrame, lastFrame);
    int startFrame = middleFrame - (SAMPLES_IN_DISPLAY ~/ 2) <= firstFrame
        ? firstFrame
        : middleFrame - (SAMPLES_IN_DISPLAY ~/ 2);
    int endFrame = middleFrame + (SAMPLES_IN_DISPLAY ~/ 2) >= lastFrame
        ? lastFrame
        : middleFrame + (SAMPLES_IN_DISPLAY ~/ 2);

    return _path(_scaledData.sublist(startFrame, middleFrame),
        _scaledData.sublist(middleFrame, endFrame), size);
  }

  Path _path(List<double> startSamples, List<double> endSamples, Size size) {
    final middleHeight = size.height / 2;
    final middleWidth = size.width / 2;

    List<Offset> minPointsStart = [];
    List<Offset> maxPointsStart = [];
    List<Offset> minPointsEnd = [];
    List<Offset> maxPointsEnd = [];

    final t = size.width / SAMPLES_IN_DISPLAY;

    for (var _i = startSamples.length - 1, _offset = 0;
        _i >= 0;
        _i--, _offset++) {
      var d = startSamples[_i];

      if (_i % 2 != 0) {
        minPointsStart.add(
            Offset(middleWidth - t * _offset, middleHeight - middleHeight * d));
      } else {
        maxPointsStart.add(
            Offset(middleWidth - t * _offset, middleHeight - middleHeight * d));
      }
    }

    for (var _i = 0; _i < endSamples.length; _i++) {
      var d = endSamples[_i];

      if (_i % 2 != 0) {
        minPointsEnd
            .add(Offset(middleWidth + t * _i, middleHeight - middleHeight * d));
      } else {
        maxPointsEnd
            .add(Offset(middleWidth + t * _i, middleHeight - middleHeight * d));
      }
    }

    final path = Path();
    path.moveTo(middleWidth, middleHeight);

    if (maxPointsStart.isNotEmpty && minPointsStart.isNotEmpty) {
      path.moveTo(maxPointsStart.first.dx, middleHeight);
      maxPointsStart.forEach((o) => path.lineTo(o.dx, o.dy));
      // back to zero
      path.lineTo(maxPointsStart.last.dx, middleHeight);
      // draw the minimums backwards so we can fill the shape when done.
      minPointsStart.reversed.forEach(
          (o) => path.lineTo(o.dx, middleHeight - (middleHeight - o.dy)));
    }

    minPointsEnd.forEach((o) => path.lineTo(o.dx, o.dy));
    path.lineTo(minPointsEnd.last.dx, middleHeight);
    maxPointsEnd.reversed.forEach(
        (o) => path.lineTo(o.dx, middleHeight - (middleHeight - o.dy)));

    path.close();
    return path;
  }

  bool _isDataScaled() {
    return _scaledData != null && _scaledData.length == data.length;
  }

  // scale the data from int values to float
  _scaleData() {
    int max = 0;

    for (var i = 0; i < data.length; i++) {
      if (data[i] > max) {
        max = data[i];
      }
    }

    final dataSize = data.length;
    _scaledData = List.filled(dataSize, 0.0);
    for (var i = 0; i < dataSize; i++) {
      _scaledData[i] = data[i].toDouble() / max;
      if (_scaledData[i] > 1.0) {
        _scaledData[i] = 1.0;
      }
      if (_scaledData[i] < -1.0) {
        _scaledData[i] = -1.0;
      }
    }
  }
}
