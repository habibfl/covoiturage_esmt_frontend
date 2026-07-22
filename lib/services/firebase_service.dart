import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    _initialized = true;
  }

  static Future<void> updateLocation(
    String tripId,
    double lat,
    double lng,
  ) async {
    await init();
    final ref = FirebaseDatabase.instance.ref('trips/$tripId/location');
    await ref.set({
      'lat': lat,
      'lng': lng,
      'ts': DateTime.now().toIso8601String(),
    });
  }

  static Stream<DatabaseEvent> listenLocation(String tripId) {
    // Note: caller must ensure FirebaseService.init() was called or access will throw
    final ref = FirebaseDatabase.instance.ref('trips/$tripId/location');
    return ref.onValue;
  }
}
