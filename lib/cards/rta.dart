import 'dart:convert';
import 'dart:io';

import 'package:MyThirdEar/utils/common.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class RTACard extends StatefulWidget {
  double height;
  double width;
  int NUMBER_OF_KEYS = 84;
  Stream<PositionData> positionDataStream;
  late Map<int, List<dynamic>> data;

  RTACard(String file,
      {required this.positionDataStream,
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
      height: widget.height,
      width: widget.width,
      child: StreamBuilder<PositionData>(
        stream: widget.positionDataStream,
        builder: (BuildContext context, AsyncSnapshot<PositionData> snapshot) {
          return snapshot.hasData
              ? CustomPaint(
                  painter: RTAPainter(widget
                      .data[getMapIndexFromPositionData(snapshot.data!)]!
                      .skip(4)
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

    return (widget.data.length * percent).floor();
  }
}

class RTAPainter extends CustomPainter {
  List<double> data;

  RTAPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    var paint1 = Paint()
      ..color = Color(0xFF000000)
      ..style = PaintingStyle.fill;

    double keyPadding = 0.5;
    double widthPerKey = (size.width / data.length);
    double keyWidth = widthPerKey - keyPadding;

    for (int i = 0; i < data.length; i++) {
      canvas.drawRect(
          Offset(widthPerKey * i + keyPadding / 2,
                  size.height - size.height * data[i]) &
              Size(keyWidth - keyPadding, size.height * data[i]),
          paint1);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
