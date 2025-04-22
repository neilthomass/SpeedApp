import 'package:flutter/material.dart';

class SpeedDisplay extends StatelessWidget {
  final double currentSpeed;
  final double suggestedSpeed;
  final bool isDarkMode;
  final bool isWarningActive;
  
  const SpeedDisplay({
    Key? key,
    required this.currentSpeed,
    required this.suggestedSpeed,
    required this.isDarkMode,
    this.isWarningActive = false,
  }) : super(key: key);
  
  Color _getSpeedColor() {
    if (!isWarningActive) return Colors.blue[400]!;
    return currentSpeed > suggestedSpeed ? Colors.red : Colors.orange;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  "Current",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  "${currentSpeed.toInt()}",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getSpeedColor(),
                  ),
                ),
              ],
            ),
            SizedBox(width: 30),
            Column(
              children: [
                Text(
                  "Suggested",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  "${suggestedSpeed.toInt()}",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[400],
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          "MPH",
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        if (isWarningActive) ...[
          SizedBox(height: 8),
          Text(
            currentSpeed > suggestedSpeed ? "Slowdown" : "Speedup",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getSpeedColor(),
            ),
          ),
        ],
      ],
    );
  }
} 