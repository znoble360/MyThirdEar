import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SpeedCard extends StatelessWidget {
  SpeedCard(this.player);

  final AudioPlayer player;

  void setSpeed(double delta) {
    final double currentSpeed = player.speed;

    // Don't allow speed to be below or equal to 0, or greater than 2.
    if (currentSpeed + delta <= 0 || currentSpeed + delta > 2) {
      return;
    }

    this.player.setSpeed(currentSpeed + delta);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: IconButton(
                  icon: Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    setSpeed(-0.05);
                  },
                ),
              ),
              Expanded(
                flex: 4,
                child: StreamBuilder<double>(
                  stream: player.speedStream,
                  builder: (context, snapshot) => Text(
                    "${snapshot.data?.toStringAsFixed(2)}x",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                  flex: 3,
                  child: IconButton(
                    icon: Icon(Icons.arrow_drop_up),
                    onPressed: () {
                      setSpeed(0.05);
                    },
                  )),
            ],
          ),
          Text("Speed"),
        ],
      ),
    );
  }
}
