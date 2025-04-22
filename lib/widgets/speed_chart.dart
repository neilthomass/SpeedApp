import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/speed_data.dart';

class SpeedChart extends StatelessWidget {
  final SpeedChartData chartData;
  final bool isDarkMode;
  final bool isRightChart;
  
  const SpeedChart({
    Key? key,
    required this.chartData,
    required this.isDarkMode,
    this.isRightChart = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: chartData.minY,
          maxY: chartData.maxY,
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          lineTouchData: LineTouchData(enabled: false),
          backgroundColor: Colors.transparent,
          lineBarsData: [
            // Speed line
            LineChartBarData(
              spots: isRightChart ? chartData.suggestedSpeedData : chartData.speedData,
              preventCurveOverShooting: false,
              barWidth: 3.0,
              curveSmoothness: 0.35,
              isCurved: true,
              isStrokeCapRound: true,
              color: Colors.blue[400],
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withAlpha(25),
              ),
            ),
            if (!isRightChart) ...[
              // Vertical red line at right edge
              LineChartBarData(
                spots: [
                  FlSpot(chartData.speedData.last.x, chartData.minY),
                  FlSpot(chartData.speedData.last.x, chartData.maxY),
                ],
                preventCurveOverShooting: true,
                barWidth: 2.0,
                isCurved: false,
                isStrokeCapRound: true,
                color: Colors.red,
                dotData: FlDotData(show: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DotPainter extends CustomPainter {
  final Offset dotPosition;
  final Offset yAxisRange;
  final double chartHeight;
  final bool isDarkMode;
  
  DotPainter({
    required this.dotPosition,
    required this.yAxisRange,
    required this.chartHeight,
    required this.isDarkMode,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final double halfWidth = size.width / 2;
    final double normalizedY = (dotPosition.dy - yAxisRange.dx) / (yAxisRange.dy - yAxisRange.dx);
    final double dotX = halfWidth;
    final double dotY = chartHeight - (normalizedY * chartHeight);
    
    final Paint dotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final Paint strokePaint = Paint()
      ..color = isDarkMode ? Color(0xFF2C2C2C) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(Offset(dotX, dotY), 5, strokePaint);
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
  }
  
  @override
  bool shouldRepaint(DotPainter oldDelegate) {
    return oldDelegate.dotPosition != dotPosition ||
           oldDelegate.yAxisRange != yAxisRange ||
           oldDelegate.isDarkMode != isDarkMode;
  }
} 