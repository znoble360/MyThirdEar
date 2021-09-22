import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

const SEMITONE_RATIOS = [
  1.00,
  1.059,
  1.122,
  1.189,
  1.260,
  1.335,
  1.414,
  1.498,
  1.587,
  1.682,
  1.782,
  1.888,
  2.000
];

class PitchCard extends StatefulWidget {
  PitchCard(this.player) : semitone = 0;

  final AudioPlayer player;
  final int semitone;

  @override
  State<PitchCard> createState() => _PitchCardState();
}

class _PitchCardState extends State<PitchCard> {
  int semitone = 0;

  @override
  void initState() {
    super.initState();

    semitone = 0;
  }

  void setNewPitch(int delta) {
    // Do not change pitch higher or lower than one octave
    if ((this.semitone + delta).abs() > 12) {
      return;
    }

    this.semitone += delta;

    var newPitch = this.semitone >= 0
        ? SEMITONE_RATIOS[this.semitone]
        : 1.0 / SEMITONE_RATIOS[this.semitone.abs()];

    widget.player.setPitch(newPitch);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: IconButton(
              icon: Icon(Icons.arrow_drop_down),
              onPressed: () {
                setState(() => setNewPitch(-1));
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              this.semitone.toString() + "st",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
              flex: 3,
              child: IconButton(
                icon: Icon(Icons.arrow_drop_up),
                onPressed: () {
                  setState(() => setNewPitch(1));
                },
              )),
        ],
      ),
    );
  }
}
