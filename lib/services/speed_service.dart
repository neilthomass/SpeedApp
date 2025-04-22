import 'dart:async';
import 'package:location/location.dart';
import '../models/speed_data.dart';

class SpeedService {
  final Location _location = Location();
  final _speedController = StreamController<SpeedData>.broadcast();
  StreamSubscription<LocationData>? _locationSubscription;
  
  Stream<SpeedData> get speedStream => _speedController.stream;
  
  Future<void> initialize() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    var permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 500,
      distanceFilter: 0,
    );

    _locationSubscription = _location.onLocationChanged.listen(_onLocationUpdate);
  }
  
  void _onLocationUpdate(LocationData locationData) {
    final speed = (locationData.speed ?? 0) * 2.23694; // Convert m/s to mph
    _speedController.add(SpeedData(
      speed: speed,
      timestamp: DateTime.now(),
    ));
  }
  
  double calculateSuggestedSpeed(double currentSpeed) {
    // Example algorithm - can be customized based on requirements
    const double targetSpeedLimit = 55.0;
    if (currentSpeed < targetSpeedLimit) {
      return (currentSpeed + 5.0).clamp(0.0, targetSpeedLimit);
    } else {
      return (currentSpeed - 3.0).clamp(0.0, targetSpeedLimit);
    }
  }
  
  void dispose() {
    _locationSubscription?.cancel();
    _speedController.close();
  }
} 