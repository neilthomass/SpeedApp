import 'package:flutter/material.dart';
import '../models/speed_data.dart';
import 'dart:math';

class LaneDisplay extends StatelessWidget {
  final List<LaneData> lanes;
  final bool isDarkMode;
  
  const LaneDisplay({
    Key? key,
    required this.lanes,
    required this.isDarkMode,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < lanes.length; i++) ...[
                  if (i > 0) SizedBox(width: 12),
                  Expanded(child: _buildLane(lanes[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLane(LaneData lane) {
    // Calculate color based on speed (red at 0 mph, green at 70+ mph)
    double speedFactor = min(1.0, lane.speed / 70.0);
    Color laneColor = Color.lerp(
      Colors.red,
      Colors.green,
      speedFactor,
    )!;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: lane.isCurrentLane ? Border.all(
          color: isDarkMode ? Colors.white : Colors.black,
          width: 2,
        ) : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              lane.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: laneColor.withAlpha(76),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${lane.speed.toInt()}",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: laneColor,
                      ),
                    ),
                    Text(
                      "MPH",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 