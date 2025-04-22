import 'package:fl_chart/fl_chart.dart';

class SpeedData {
  final double speed;
  final DateTime timestamp;

  SpeedData({
    required this.speed,
    required this.timestamp,
  });
}

class SpeedChartData {
  final List<FlSpot> speedData;
  final List<FlSpot> suggestedSpeedData;
  final double minY;
  final double maxY;

  SpeedChartData({
    required this.speedData,
    required this.suggestedSpeedData,
    required this.minY,
    required this.maxY,
  });

  factory SpeedChartData.empty() {
    return SpeedChartData(
      speedData: List.generate(30, (index) => FlSpot(index * 0.03, 0)),
      suggestedSpeedData: List.generate(30, (index) => FlSpot(index * 0.03, 0)),
      minY: 0,
      maxY: 40,
    );
  }
}

class LaneData {
  final String label;
  final double speed;
  final bool isCurrentLane;

  LaneData({
    required this.label,
    required this.speed,
    this.isCurrentLane = false,
  });
} 