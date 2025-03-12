import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';  // Changed from geolocator
import 'settings_page.dart';
import 'package:flutter/services.dart';




enum SpeedUnit { mph, kph }


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
  LocationData? _locationData;
  StreamSubscription<LocationData>? _locationSubscription;
  
  double _currentSpeed = 0.0;
  double _currentDisplaySpeed = 0.0;
  double _targetSpeed = 0.0;
  final List<FlSpot> _speedData = [FlSpot(0, 0)];
  final List<Map<String, String>> _locationLog = [];
  
  Timer? _graphUpdateTimer;
  Timer? _interpolationTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _graphUpdateTimer = Timer.periodic(Duration(milliseconds: graphUpdateRate), _updateGraph);
    _interpolationTimer = Timer.periodic(Duration(milliseconds: graphUpdateRate), _interpolateSpeed);
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

  void _updateLocation(LocationData locationData) {
    setState(() {
      _currentSpeed = (locationData.speed ?? 0) * 2.23694; // Convert m/s to mph
      _targetSpeed = _currentSpeed;
      
      String timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
      _locationLog.insert(0, {
        "latlon": "Lat: ${locationData.latitude?.toStringAsFixed(5)}, Lon: ${locationData.longitude?.toStringAsFixed(5)}", 
        "timestamp": timestamp
      });
      if (_locationLog.length > 20) _locationLog.removeLast();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _graphUpdateTimer?.cancel();
    _interpolationTimer?.cancel();
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

    SpeedUnit _currentUnit = SpeedUnit.mph;

    double _convertSpeed(double speed) {
      return _currentUnit == SpeedUnit.kph ? speed * 1.60934 : speed;
    }


  void _updateGraph(Timer timer) {
    setState(() {
      // Smooth out the data points
      for (int i = 0; i < _speedData.length; i++) {
        _speedData[i] = FlSpot(_speedData[i].x - 0.03, _speedData[i].y);  // Reduced movement speed
      }

      _speedData.add(FlSpot(_speedData.last.x + 0.03, _currentDisplaySpeed));

      if (_speedData.length > 30) _speedData.removeAt(0);
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    const double earthRadiusMiles = 3959;
    return earthRadiusMiles * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRadians(double degrees) => degrees * pi / 180;



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
              child: _buildSpeedChart(),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 8,
                color: widget.isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _buildLocationLog(),
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
        Text(
          "${(_convertSpeed(_currentDisplaySpeed)).toInt()}",
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentUnit == SpeedUnit.mph ? "MPH" : "KPH",
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.swap_horiz, 
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]
              ),
              onPressed: () {
                setState(() {
                  _currentUnit = _currentUnit == SpeedUnit.mph ? 
                    SpeedUnit.kph : SpeedUnit.mph;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedChart() {
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

    // Calculate dynamic y-axis range based on the latest speed data
    double latestY = _speedData.last.y;
    double yRange = 40.0; // Default range for normal speed changes
    double minY = latestY - yRange / 2;
    double maxY = latestY + yRange / 2;

    // Check for sudden changes in speed
    double minSpeed = _speedData.map((spot) => spot.y).reduce(min);
    double maxSpeed = _speedData.map((spot) => spot.y).reduce(max);
    if ((maxSpeed - minSpeed) > 10) {
      // Adjust y-axis range if speed differs by more than 10 mph
      minY = minSpeed - 5.0; // Add some padding
      maxY = maxSpeed + 5.0; // Add some padding
    }

    return SizedBox(
      height: 180,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            lineTouchData: LineTouchData(enabled: false),
            backgroundColor: Colors.transparent,
            lineBarsData: [
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
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationLog() {
    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: _locationLog.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 8.0),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locationLog[index]["timestamp"]!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Expanded(
                child: Text(
                  _locationLog[index]["latlon"]!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}