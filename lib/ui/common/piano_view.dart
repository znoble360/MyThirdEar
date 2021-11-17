import 'package:flutter/material.dart';
import 'package:musictranscriptiontools/ui/home/theme.dart';

import 'package:musictranscriptiontools/ui/common/piano_octave.dart';
import 'package:musictranscriptiontools/ui/common/piano_section.dart';
import 'package:musictranscriptiontools/ui/common/piano_slider.dart';

class PianoView extends StatefulWidget {
  const PianoView({
    this.showLabels = true,
    this.keyWidth = 7,
    required this.labelsOnlyOctaves,
    this.disableScroll = false,
    this.feedback = true,
  });

  final double keyWidth;
  final bool showLabels;
  final bool labelsOnlyOctaves;
  final bool disableScroll;
  final bool feedback;

  @override
  _PianoViewState createState() => _PianoViewState();
}

class _PianoViewState extends State<PianoView> {
  int _currentOctave = 3;
  late ScrollController _controller = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true
  );

  @override
  void initState() {
    _controller = ScrollController(initialScrollOffset: currentOffset);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      children: <Widget>[
        Flexible(
          flex: 1,
          child: Container(
            child: PianoSlider(
              theme: ThemeUtils(context),
              keyWidth: widget.keyWidth,
              currentOctave: _currentOctave,
              octaveTapped: (int octave) {
                setState(() {
                  _currentOctave = octave;
                });
                _controller.jumpTo(currentOffset);
              },
            ),
          ),
        ),
        Flexible(
          flex: 8,
          child: PianoSection(
            controller: _controller,
            disableScroll: widget.disableScroll,
            keyWidth: widget.keyWidth,
            showLabels: widget.showLabels,
            labelsOnlyOctaves: widget.labelsOnlyOctaves,
            feedback: widget.feedback,
          ),
        ),
      ],
    );
  }

  double get currentOffset => widget.keyWidth * (7 * _currentOctave);
  
}