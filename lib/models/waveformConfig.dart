import 'package:MyThirdEar/utils/common.dart';

class WaveformConfig {
  double startPercentage = 0.0;
  double endPercentage = 1.0;
  Stream<PositionData>? positionDataStream;

  WaveformConfig();

  void setToDefault() {
    startPercentage = 0.0;
    endPercentage = 1.0;
  }
}
