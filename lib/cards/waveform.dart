import 'package:flutter/material.dart';
import 'package:musictranscriptiontools/utils/waveform.dart';

class PaintedWaveform extends StatefulWidget {
  PaintedWaveform({
    Key? key,
    @required this.sampleData,
  }) : super(key: key);

  final WaveformData? sampleData;

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
                          startingFrame: widget.sampleData!
                              .frameIdxFromPercent(startPosition),
                          color: Color(0xff3994DB),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Flexible(
            child: Slider(
              activeColor: Colors.indigoAccent,
              min: 0.0,
              max: 100.0,
              divisions: 42,
              onChanged: (newstartPosition) {
                setState(() => startPosition = newstartPosition);
              },
              value: startPosition,
            ),
          )
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final WaveformData data;
  final int startingFrame;
  final double zoomLevel;
  Paint? painter;
  final Color color;
  final double strokeWidth;

  WaveformPainter(this.data,
      {this.strokeWidth = 1.0,
      this.startingFrame = 0,
      this.zoomLevel = 1,
      this.color = Colors.blue}) {
    painter = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        data.path(size, fromFrame: startingFrame, zoomLevel: zoomLevel);
    canvas.drawPath(path, painter!);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    if (oldDelegate.data != data) {
      debugPrint("Redrawing");
      return true;
    }
    return false;
  }
}
