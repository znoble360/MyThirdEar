import 'package:MyThirdEar/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:MyThirdEar/utils/waveform.dart';

class PaintedWaveform extends StatefulWidget {
  PaintedWaveform({
    Key? key,
    @required this.sampleData,
    @required this.positionDataStream,
  }) : super(key: key);

  final WaveformData? sampleData;
  final Stream<PositionData>? positionDataStream;

  @override
  _PaintedWaveformState createState() => _PaintedWaveformState();
}

class _PaintedWaveformState extends State<PaintedWaveform> {
  double startPosition = 0.0;

  @override
  Widget build(context) {
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            flex: 4,
            child: LayoutBuilder(
              builder: (context, BoxConstraints constraints) {
                // adjust the shape based on parent's orientation/shape
                // the waveform should always be wider than taller
                var height;
                if (constraints.maxWidth < constraints.maxHeight) {
                  height = constraints.maxWidth;
                } else {
                  height = constraints.maxHeight;
                }

                return StreamBuilder<PositionData>(
                    stream: widget.positionDataStream,
                    builder: (BuildContext context2,
                        AsyncSnapshot<PositionData> snapshot2) {
                      startPosition = snapshot2.data == null
                          ? 0.0
                          : snapshot2.data!.position.inMilliseconds.toDouble() /
                              snapshot2.data!.duration.inMilliseconds
                                  .toDouble();

                      return Container(
                        child: Row(
                          children: <Widget>[
                            CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                height,
                              ),
                              foregroundPainter: WaveformPainter(
                                widget.sampleData!,
                                percent: startPosition,
                                color: Color(0xff3994DB),
                              ),
                            ),
                          ],
                        ),
                      );
                    });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final WaveformData data;
  final double percent;
  Paint? painter;
  final Color color;
  final double strokeWidth;

  WaveformPainter(this.data,
      {this.strokeWidth = 1.0, this.percent = 0.0, this.color = Colors.blue}) {
    painter = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = data.path(size, percent);
    canvas.drawPath(path, painter!);

    var paint1 = Paint()
      ..color = Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset(size.width / 2, 0) & Size(2, size.height), paint1);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return true;
  }
}
