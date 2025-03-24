import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';  // Changed from geolocator
import 'settings_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';


// Custom painter for the dot at the transition point
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
    // Calculate the position of the dot in the actual widget space
    final double halfWidth = size.width / 2;
    final double normalizedY = (dotPosition.dy - yAxisRange.dx) / (yAxisRange.dy - yAxisRange.dx);
    final double dotX = halfWidth; // Position at the center (between the charts)
    final double dotY = chartHeight - (normalizedY * chartHeight);
    
    // Draw the dot
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


void main() {
  
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: SpeedTracker(isDarkMode: _isDarkMode, onThemeChanged: _toggleTheme),
    );
  }
}


class SpeedTracker extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SpeedTracker({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _SpeedTrackerState createState() => _SpeedTrackerState();
}


class _SpeedTrackerState extends State<SpeedTracker> {
  static const int graphUpdateRate = 100;
  
  final Location location = Location();
  final FlutterTts flutterTts = FlutterTts();
  
  StreamSubscription<LocationData>? _locationSubscription;
  
  double _currentSpeed = 0.0;
  double _currentDisplaySpeed = 0.0;
  double _targetSpeed = 0.0;
  double _suggestedSpeed = 0.0; // New variable for recommended speed
  final List<FlSpot> _speedData = List.generate(30, (index) => FlSpot(index * 0.03, 0));
  final List<FlSpot> _suggestedSpeedData = List.generate(30, (index) => FlSpot(index * 0.03, 0)); // Predicted future speed data
  final List<Map<String, String>> _locationLog = [];
  
  // TTS warning variables
  bool _isWarningActive = false;
  DateTime? _warningStartTime;
  Timer? _warningTimer;
  
  Timer? _graphUpdateTimer;
  Timer? _interpolationTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _initializeTts();
    _graphUpdateTimer = Timer.periodic(Duration(milliseconds: graphUpdateRate), _updateGraph);
    _interpolationTimer = Timer.periodic(Duration(milliseconds: graphUpdateRate), _interpolateSpeed);
    _warningTimer = Timer.periodic(Duration(milliseconds: 500), _checkSpeedDifference);
  }

  Future<void> _initializeLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Configure location settings
    await location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 500, // Update interval in milliseconds
      distanceFilter: 0,
    );

    // Start listening to location updates
    _locationSubscription = location.onLocationChanged.listen(_updateLocation);
  }

  Future<void> _initializeTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    // Set better engine parameters
    if (await flutterTts.isLanguageAvailable("en-US")) {
      print("Language is available");
    }
    
    // Error handler to debug TTS issues
    flutterTts.setErrorHandler((msg) {
      print("TTS ERROR: $msg");
    });
  }
  
  // Check if speed differs from suggested speed by more than 10 mph
  void _checkSpeedDifference(Timer timer) {
    double speedDiff = (_currentDisplaySpeed - _suggestedSpeed).abs();
    
    if (speedDiff > 10) {
      // If this is the first detection of significant speed difference
      if (!_isWarningActive) {
        _isWarningActive = true;
        _warningStartTime = DateTime.now();
      } else {
        // Calculate how long the speed has been significantly different
        Duration timeDiff = DateTime.now().difference(_warningStartTime!);
        
        // If it's been over 5 seconds, play the TTS warning
        if (timeDiff.inSeconds >= 30 && !_isPlaying) {
          if (_currentDisplaySpeed > _suggestedSpeed) {
            _speakWarning("Slow down");
          } else {
            _speakWarning("Speed up");
          }
        }
      }
    } else {
      // Reset the warning state when speed is close to suggested
      _isWarningActive = false;
      _warningStartTime = null;
    }
  }
  
  bool _isPlaying = false;
  
  Future<void> _speakWarning(String message) async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        await flutterTts.speak(message);
        // Wait long enough for the message to complete before allowing another
        await Future.delayed(Duration(seconds: 10));
      } catch (e) {
        print("TTS ERROR: $e");
      } finally {
        _isPlaying = false;
      }
    }
  }

  void _updateLocation(LocationData locationData) {
    setState(() {
      _currentSpeed = (locationData.speed ?? 0) * 2.23694; // Convert m/s to mph
      _targetSpeed = _currentSpeed;
      
      // Generate a suggested speed (this is a simple example - you can replace with your algorithm)
      // For example, this gently transitions toward a target speed of 55 mph
      double targetSpeedLimit = 55.0;
      //_suggestedSpeed = _currentSpeed < targetSpeedLimit ?
      //    min(_currentSpeed + 5.0, targetSpeedLimit) : // If below target, accelerate gently
      //    max(_currentSpeed - 3.0, targetSpeedLimit);  // If above target, decelerate gently
      
      // Update the suggested speed data
      _updateSuggestedSpeedData();
      
      String timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
      _locationLog.insert(0, {
        "latlon": "Lat: ${locationData.latitude?.toStringAsFixed(5)}, Lon: ${locationData.longitude?.toStringAsFixed(5)}", 
        "timestamp": timestamp
      });
      if (_locationLog.length > 20) _locationLog.removeLast();
    });
  }

  // Generate predictive data for suggested speed transition
  void _updateSuggestedSpeedData() {
    // Make sure we have the current speed at position 0
    double startSpeed = _currentDisplaySpeed;
    double endSpeed = _suggestedSpeed;
    
    // Generate 30 points showing transition from current to suggested speed
    for (int i = 0; i < 30; i++) {
      double progress = i / 29.0; // 0.0 to 1.0
      double speed;
      
      // Create a smooth transition using a cubic ease-in-out curve
      if (progress < 0.5) {
        // Ease in - slower at the beginning
        speed = startSpeed + (endSpeed - startSpeed) * (4 * progress * progress * progress);
      } else {
        // Ease out - slower at the end
        double t = progress - 1;
        speed = startSpeed + (endSpeed - startSpeed) * (1 + 4 * t * t * t);
      }
      
      // First point should match exactly with the current speed to ensure continuity
      if (i == 0) {
        speed = startSpeed;
      }
      
      // Start the future graph points slightly after the current position to avoid overlap with the dot
      _suggestedSpeedData[i] = FlSpot((i * 0.03) + 0.01, speed);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _graphUpdateTimer?.cancel();
    _interpolationTimer?.cancel();
    _warningTimer?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  void _interpolateSpeed(Timer timer) {
    if (_currentDisplaySpeed != _targetSpeed) {
      setState(() {
        double difference = (_targetSpeed - _currentDisplaySpeed) * 0.2;
        _currentDisplaySpeed += difference;
      });
    }
  }

  void _updateGraph(Timer timer) {
    setState(() {
      // Shift all points to the left
      for (int i = 0; i < _speedData.length; i++) {
        _speedData[i] = FlSpot(_speedData[i].x - 0.03, _speedData[i].y);
      }

      // Add new point at the right edge, maintaining the x-distance
      _speedData.add(FlSpot(_speedData.last.x + 0.03, _currentDisplaySpeed));

      // Keep only the latest 30 points to maintain graph size
      if (_speedData.length > 30) {
        _speedData.removeAt(0);
      }
      
      // Update the suggested speed data regularly
      _updateSuggestedSpeedData();
    });
  }

  // Calculate y-axis range for both graphs to ensure consistent scaling
  Map<String, double> _calculateYAxisRange() {
    if (_speedData.isEmpty) {
      return {'minY': 0, 'maxY': 40};
    }
    
    // Calculate dynamic y-axis range based on the latest speed data
    double latestY = _speedData.last.y;
    double yRange = 40.0; // Default range for normal speed changes
    
    // Get min/max from both actual and suggested speed data
    double minSpeed = _speedData.map((spot) => spot.y).reduce(min);
    double maxSpeed = _speedData.map((spot) => spot.y).reduce(max);
    
    // Also consider suggested speed data
    double minSuggested = _suggestedSpeedData.map((spot) => spot.y).reduce(min);
    double maxSuggested = _suggestedSpeedData.map((spot) => spot.y).reduce(max);
    
    // Use the overall min/max from both datasets
    minSpeed = min(minSpeed, minSuggested);
    maxSpeed = max(maxSpeed, maxSuggested);
    
    double minY = latestY - yRange / 2;
    double maxY = latestY + yRange / 2;
    
    // Adjust for extreme speed values
    if ((maxSpeed - minSpeed) > 10) {
      minY = minSpeed - 5.0;
      maxY = maxSpeed + 5.0;
    }
    
    return {'minY': minY, 'maxY': maxY};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          icon: Icon(Icons.menu, color: Colors.white),
          color: Color(0xFF2C2C2C),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'speed',
              child: Row(
                children: [
                  Icon(Icons.speed, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Speed Tracker', 
                    style: TextStyle(color: Colors.white)
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Settings', 
                    style: TextStyle(color: Colors.white)
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: widget.isDarkMode,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            }
          },
        ),
        title: Text("Speed Tracker",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white
          )
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Card(
              elevation: 8,
              color: widget.isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: _buildSpeedDisplay(),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 8,
              color: widget.isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: _buildSpeedChart(showDot: false),
                      ),
                      Expanded(
                        child: _buildRightSpeedChart(),
                      ),
                    ],
                  ),
                  // Overlay the red dot on top of both charts to ensure it's visible
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0, 
                    child: _buildCenterDot(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 8,
                color: widget.isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _buildLanesVisualization(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDisplay() {
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
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  "${_currentDisplaySpeed.toInt()}",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[400],
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
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  "${_suggestedSpeed.toInt()}",
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
            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedChart({bool showDot = true}) {
    if (_speedData.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No data",
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black
            ),
          ),
        ),
      );
    }

    // Get y-axis range from the common function
    final yAxisRange = _calculateYAxisRange();
    double minY = yAxisRange['minY']!;
    double maxY = yAxisRange['maxY']!;

    // Get the right edge position
    double rightEdgeX = _speedData.last.x;

    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              lineTouchData: LineTouchData(enabled: false),
              backgroundColor: Colors.transparent,
              lineBarsData: [
                // Speed line
                LineChartBarData(
                  spots: _speedData,
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
                // Vertical red line at right edge
                LineChartBarData(
                  spots: [
                    FlSpot(rightEdgeX, minY),
                    FlSpot(rightEdgeX, maxY),
                  ],
                  preventCurveOverShooting: true,
                  barWidth: 2.0,
                  isCurved: false,
                  isStrokeCapRound: true,
                  color: Colors.red,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add a method to create just the center red dot
  Widget _buildCenterDot() {
    if (_speedData.isEmpty) return Container();
    
    // Get y-axis range and current position
    final yAxisRange = _calculateYAxisRange();
    double minY = yAxisRange['minY']!;
    double maxY = yAxisRange['maxY']!;
    
    // Calculate position of the transition point
    double rightEdgeX = _speedData.last.x;
    double currentY = _speedData.last.y;
    
    // Create a custom painter for the single dot
    return CustomPaint(
      painter: DotPainter(
        dotPosition: Offset(rightEdgeX, currentY),
        yAxisRange: Offset(minY, maxY),
        chartHeight: 180.0,
        isDarkMode: widget.isDarkMode,
      ),
    );
  }

  // New function for right speed chart
  Widget _buildRightSpeedChart() {
    if (_speedData.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No data",
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black
            ),
          ),
        ),
      );
    }

    // Get y-axis range from the common function
    final yAxisRange = _calculateYAxisRange();
    double minY = yAxisRange['minY']!;
    double maxY = yAxisRange['maxY']!;

    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              lineTouchData: LineTouchData(enabled: false),
              backgroundColor: Colors.transparent,
              lineBarsData: [
                // Suggested speed line
                LineChartBarData(
                  spots: _suggestedSpeedData,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Create new lanes visualization to replace the location log
  Widget _buildLanesVisualization() {
    // Calculate lane speeds
    double currentLaneSpeed = _currentDisplaySpeed;
    double leftLaneSpeed = max(0, _currentDisplaySpeed - 20);
    double rightLaneSpeed = _currentDisplaySpeed + 20;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                // Left lane
                Expanded(
                  child: _buildLane("Left Lane", leftLaneSpeed),
                ),
                SizedBox(width: 12),
                // Current lane
                Expanded(
                  child: _buildLane("Your Lane", currentLaneSpeed, isCurrentLane: true),
                ),
                SizedBox(width: 12),
                // Right lane
                Expanded(
                  child: _buildLane("Right Lane", rightLaneSpeed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build each lane
  Widget _buildLane(String label, double speed, {bool isCurrentLane = false}) {
    // Calculate color based on speed (red at 0 mph, green at 70+ mph)
    double speedFactor = min(1.0, speed / 70.0);
    Color laneColor = Color.lerp(
      Colors.red,
      Colors.green,
      speedFactor,
    )!;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isCurrentLane ? Border.all(
          color: widget.isDarkMode ? Colors.white : Colors.black,
          width: 2,
        ) : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: laneColor.withAlpha(76), // 0.3 transparency as alpha (0.3 * 255 ≈ 76)
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${speed.toInt()}",
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
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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

  // Build a visual indicator showing time until warning
  Widget _buildWarningIndicator() {
    // Calculate the percentage of the 5-second window that has passed
    Duration timeDiff = _warningStartTime != null ? 
        DateTime.now().difference(_warningStartTime!) : 
        Duration.zero;
    double percentage = min(1.0, timeDiff.inMilliseconds / 5000.0);
    String message = _currentDisplaySpeed > _suggestedSpeed ? "Slowdown" : "Speedup";
    
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          width: 150,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          child: Row(
            children: [
              Container(
                width: 150 * percentage,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentDisplaySpeed > _suggestedSpeed ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _currentDisplaySpeed > _suggestedSpeed ? Colors.red : Colors.orange,
          ),
        ),
      ],
    );
  }
}