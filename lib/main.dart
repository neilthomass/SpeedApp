import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

main() => runApp(MaterialApp(home: SpeedTracker()));

class SpeedTracker extends StatefulWidget {
  @override
  _SpeedTrackerState createState() => _SpeedTrackerState();
}

class _SpeedTrackerState extends State<SpeedTracker> {
  static const double earthRadiusMiles = 3958.8;
  static const int graphUpdateRate = 100;
  static const int speedMeasureRate = 500;

  double _lastMeasuredSpeed = 0.0;
  int _currentIndex = 0;
  double? _prevLat, _prevLon;
  final List<FlSpot> _speedData = [FlSpot(0, 0)];
  final List<Map<String, String>> _locationLog = [];

  Timer? _speedTimer;
  Timer? _graphUpdateTimer;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _graphUpdateTimer = Timer.periodic(Duration(milliseconds: graphUpdateRate), _updateGraph);
  }

  Future<void> _requestLocationPermission() async {
    bool permissionGranted = await requestLocationPermission();
    if (permissionGranted) {
      _startLocationUpdates();
    } else {
      print("Location permissions are denied.");
    }
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void _startLocationUpdates() {
    _speedTimer = Timer.periodic(Duration(milliseconds: speedMeasureRate), _updateSpeed);
  }

  void _updateSpeed(Timer timer) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;
      String timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());

      if (_prevLat != null && _prevLon != null) {
        double distance = _calculateDistance(_prevLat!, _prevLon!, lat, lon);
        _lastMeasuredSpeed = distance * 3600 / (speedMeasureRate / 1000);
      }

      _prevLat = lat;
      _prevLon = lon;
      _currentIndex++;

      setState(() {
        _locationLog.insert(0, {
          "latlon": "Lat: ${lat.toStringAsFixed(5)}, Lon: ${lon.toStringAsFixed(5)}",
          "timestamp": timestamp
        });
        if (_locationLog.length > 20) _locationLog.removeLast();
      });
    } catch (e) {
      print("Error processing GPS data: $e");
    }
  }

  void _updateGraph(Timer timer) {
    setState(() {
      for (int i = 0; i < _speedData.length; i++) {
        _speedData[i] = FlSpot(_speedData[i].x - 0.05, _speedData[i].y);
      }
      _speedData.add(FlSpot(_speedData.last.x + 0.05, _lastMeasuredSpeed));
      if (_speedData.length > 20) _speedData.removeAt(0);
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadiusMiles * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  @override
  void dispose() {
    _speedTimer?.cancel();
    _graphUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Neil Thomas Speed Tracker", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: <Widget>[
          _buildSpeedChart(),
          _buildSpeedDisplay(),
          _buildLocationLog(),
        ],
      ),
    );
  }

  Widget _buildSpeedChart() {
    if (_speedData.isEmpty) {
      return SizedBox(height: 180, child: Center(child: Text("No data")));
    }

    double latestY = _speedData.last.y;
    double yRange = 5.0; // fixed y-axis scale of 5 mph
    double minY = latestY - yRange / 2;
    double maxY = latestY + yRange / 2;

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
            lineBarsData: [
              LineChartBarData(
                spots: _speedData,
                preventCurveOverShooting: true,
                barWidth: 4.0,
                isCurved: true,
                color: Colors.red,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDisplay() {
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 2 / 3,
        child: Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Text(
            "Speed: ${(_lastMeasuredSpeed * 100).roundToDouble() / 100} mph",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationLog() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _locationLog.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 0.5, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _locationLog[index]["timestamp"]!,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    _locationLog[index]["latlon"]!,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


