import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'error_utils.dart';
import 'firebase_service.dart';

class LocationTrackingService {
  static StreamSubscription<Position>? _positionSubscription;
  static String? _currentTripId;

  static Future<bool> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> startTracking(String tripId) async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission) return false;

    await stopTracking();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        FirebaseService.updateLocation(
          tripId,
          position.latitude,
          position.longitude,
        );
      },
      onError: (Object error) {
        logSilentError('LocationTrackingService.startTracking', error);
        stopTracking();
      },
    );
    _currentTripId = tripId;
    return true;
  }

  static Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentTripId = null;
  }

  static bool get isTracking => _positionSubscription != null;
  static String? get currentTripId => _currentTripId;
}