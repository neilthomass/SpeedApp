import 'package:flutter/material.dart';
import 'package:location/location.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsPage({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  LocationData? _currentPosition;
  final Location location = Location();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      PermissionStatus _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      LocationData position = await location.getLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        title: Text('Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2C2C2C),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: widget.isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 18,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Switch(
                          value: widget.isDarkMode,
                          onChanged: widget.onThemeChanged,
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: widget.isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 18,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _currentPosition != null
                              ? 'Lat: ${_currentPosition!.latitude?.toStringAsFixed(5)}\nLon: ${_currentPosition!.longitude?.toStringAsFixed(5)}'
                              : 'Location not available',
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 8,
            child: Text(
              'Built by Neil Thomas',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}