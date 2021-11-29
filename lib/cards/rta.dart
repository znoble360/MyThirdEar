import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:MyThirdEar/models/waveformConfig.dart';
import 'package:MyThirdEar/utils/common.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class RTACard extends StatefulWidget {
  double height;
  double width;
  int NUMBER_OF_KEYS = 84;
  WaveformConfig waveformConfig;
  late Map<int, List<dynamic>> data;

  RTACard(String file,
      {required this.waveformConfig,
      required this.height,
      required this.width}) {
    data = parseCSV(file);
  }

  Map<int, List<dynamic>> parseCSV(String file) {
    final input = new File(file);
    Map<int, List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(input.readAsStringSync()).asMap();

    return rowsAsListOfValues;
  }

  @override
  State<RTACard> createState() => _RTACardState();
}

class _RTACardState extends State<RTACard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: StreamBuilder<PositionData>(
        stream: widget.waveformConfig.positionDataStream,
        builder: (BuildContext context, AsyncSnapshot<PositionData> snapshot) {
          return snapshot.hasData
              ? CustomPaint(
                  painter: RTAPainter(widget
                      .data[getMapIndexFromPositionData(snapshot.data!)]!
                      .skip(3)
                      .map((e) => e as double)
                      .toList()),
                )
              : SizedBox();
        },
      ),
    );
  }

  int getMapIndexFromPositionData(PositionData positionData) {
    double percent = positionData.position.inMilliseconds /
        positionData.duration.inMilliseconds;

    return ((widget.data.length - 1) * percent).floor();
  }
}

class RTAPainter extends CustomPainter {
  List<double> data;

  RTAPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    var paint1 = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    var paint2 = Paint()
      ..color = Color(0xFF000000)
      ..style = PaintingStyle.fill;

    double keyPadding = 4.0;
    int numOfWhiteKeys = 7 * 7;
    double widthPerKey = (size.width / (numOfWhiteKeys));
    double sizeOfOctave = widthPerKey * 7;

    double keyWidth = widthPerKey - keyPadding;
    double blackKeyWidth = widthPerKey - keyPadding;

    Map<int, double> blackKeyLoc = {
      1: (widthPerKey * 1 - blackKeyWidth / 2),
      3: (widthPerKey * 2 - blackKeyWidth / 2),
      6: (widthPerKey * 4 - blackKeyWidth / 2),
      8: (widthPerKey * 5 - blackKeyWidth / 2),
      10: (widthPerKey * 6 - blackKeyWidth / 2),
    };

    int whiteCount = 0;
    for (int index = 0; index < data.length; index++) {
      if (!blackKeyLoc.containsKey(index % 12)) {
        canvas.drawRect(
            Offset((widthPerKey * whiteCount + keyPadding / 2).toDouble(),
                    size.height - size.height * data[index]) &
                Size(keyWidth, size.height * data[index]),
            paint1);

        whiteCount++;
      } else {
        canvas.drawRect(
            Offset((widthPerKey * whiteCount - blackKeyWidth / 2).toDouble(),
                    size.height - size.height * data[index]) &
                Size(blackKeyWidth, size.height * data[index]),
            paint2);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
