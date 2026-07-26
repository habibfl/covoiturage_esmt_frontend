import 'package:firebase_database/firebase_database.dart';

import 'error_utils.dart';

class FirebaseService {
  static DatabaseReference _locationRef(String tripId) {
    return FirebaseDatabase.instance.ref('trips/$tripId/location');
  }

  static Future<void> updateLocation(
    String tripId,
    double lat,
    double lng,
  ) async {
    try {
      await _locationRef(tripId).set({
        'lat': lat,
        'lng': lng,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      // Echec silencieux : pas d'impact bloquant si Firebase est indisponible.
      logSilentError('FirebaseService.updateLocation', e);
    }
  }

  static Stream<DatabaseEvent> listenLocation(String tripId) {
    return _locationRef(tripId).onValue;
  }

  static Future<void> clearLocation(String tripId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('trips/$tripId/location');
      await ref.remove();
    } catch (e) {
      logSilentError('FirebaseService.clearLocation', e);
    }
  }
}