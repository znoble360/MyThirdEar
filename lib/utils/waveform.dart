/*
Source: https://github.com/mattetti/waveform_demo
*/

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

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
  int frameIdxFromPercent(double percent) {
    // if the scale is 0-1.0
    if (percent < 0.0) {
      percent = 0.0;
    } else if (percent > 100.0) {
      percent = 100.0;
    }

    int maxFrame = data.length - 5000;
    int idx = (maxFrame * (percent / 100)).floor();

    return idx;
  }

  Path path(Size size, {zoomLevel = 1.0, int fromFrame = 0}) {
    if (!_isDataScaled()) {
      _scaleData();
    }

    int endFrame = fromFrame + 5000;

    print("Start frame = " + fromFrame.toString());
    print("End frame = " + endFrame.toString());
    print("Scaled data length = " + _scaledData.length.toString());

    if (endFrame >= _scaledData.length) {
      // Can't go past end of data.
      fromFrame = 0;
      endFrame = (_scaledData.length > 5000) ? 5000 : _scaledData.length;
    }

    return _path(_scaledData.sublist(fromFrame, endFrame), size);
  }

  Path _path(List<double> samples, Size size) {
    final middle = size.height / 2;
    var i = 0;

    List<Offset> minPoints = [];
    List<Offset> maxPoints = [];

    final t = size.width / samples.length;
    for (var _i = 0, _len = samples.length; _i < _len; _i++) {
      var d = samples[_i];

      if (_i % 2 != 0) {
        minPoints.add(Offset(t * i, middle - middle * d));
      } else {
        maxPoints.add(Offset(t * i, middle - middle * d));
      }

      i++;
    }

    final path = Path();
    path.moveTo(0, middle);
    maxPoints.forEach((o) => path.lineTo(o.dx, o.dy));
    // back to zero
    path.lineTo(size.width, middle);
    // draw the minimums backwards so we can fill the shape when done.
    minPoints.reversed
        .forEach((o) => path.lineTo(o.dx, middle - (middle - o.dy)));

    path.close();
    return path;
  }

  bool _isDataScaled() {
    return _scaledData != null && _scaledData.length == data.length;
  }

  // scale the data from int values to float
  _scaleData() {
    final max = pow(2, bits - 1).toDouble();

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
