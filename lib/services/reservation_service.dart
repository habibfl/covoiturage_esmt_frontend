import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'auth_service.dart';
import 'error_utils.dart';
import 'trip_service.dart';

class ReservationResult {
  final bool success;
  final String? message;
  final String? reservationId;
  final bool isAuthError;

  const ReservationResult({
    required this.success,
    this.message,
    this.reservationId,
    this.isAuthError = false,
  });
}

class ReservationService {
  static Future<ReservationResult> createReservation(
    String trajetId, {
    int nbPlacesReservees = 1,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const ReservationResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/reservations');
      final parsedTrajetId = int.tryParse(trajetId);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'trajetId': parsedTrajetId ?? trajetId,
              'nbPlacesReservees': nbPlacesReservees,
            }),
          )
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReservationResult(
          success: true,
          reservationId: body?['id']?.toString(),
        );
      }

      logNetworkError('ReservationService.createReservation', response);
      return ReservationResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return const ReservationResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const ReservationResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return ReservationResult(success: false, message: 'Erreur: $e');
    }
  }

  static Future<ReservationResult> cancelReservation(
    String reservationId,
  ) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const ReservationResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/reservations/$reservationId/cancel',
      );
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return const ReservationResult(success: true);
      }

      logNetworkError('ReservationService.cancelReservation', response);
      return ReservationResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return const ReservationResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const ReservationResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return ReservationResult(success: false, message: 'Erreur: $e');
    }
  }

  static Future<Map<String, dynamic>?> getActiveReservation() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/reservations');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        logNetworkError('ReservationService.getActiveReservation', response);
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return null;

      final relevant = decoded.cast<Map<String, dynamic>>().where((r) {
        final statut = r['statutReservation'];
        return statut == 'EN_ATTENTE' ||
            statut == 'CONFIRMEE' ||
            statut == 'REJETEE';
      }).toList();
      if (relevant.isEmpty) return null;

      relevant.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
        return idB.compareTo(idA);
      });
      return relevant.first;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getReservationsForTrip(
    String trajetId,
  ) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return [];
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/reservations/trajet/$trajetId',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        logNetworkError('ReservationService.getReservationsForTrip', response);
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<ReservationResult> confirmReservation(
    String reservationId,
  ) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const ReservationResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/reservations/$reservationId/confirm',
      );
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return const ReservationResult(success: true);
      }

      logNetworkError('ReservationService.confirmReservation', response);
      return ReservationResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return const ReservationResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const ReservationResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return ReservationResult(success: false, message: 'Erreur: $e');
    }
  }

  static Future<ReservationResult> rejectReservation(
    String reservationId,
  ) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const ReservationResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/reservations/$reservationId/reject',
      );
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return const ReservationResult(success: true);
      }

      logNetworkError('ReservationService.rejectReservation', response);
      return ReservationResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return const ReservationResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const ReservationResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return ReservationResult(success: false, message: 'Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return [];

    final trips = await TripService.getTrajetsByConducteur(userId);
    final requests = <Map<String, dynamic>>[];

    for (final trip in trips) {
      final tripId = trip['id']?.toString();
      if (tripId == null) continue;
      final reservations = await getReservationsForTrip(tripId);
      for (final res in reservations) {
        if (res['statutReservation'] == 'EN_ATTENTE') {
          requests.add({
            'reservationId': res['id']?.toString(),
            'passager': res['passager'],
            'nbPlacesReservees': res['nbPlacesReservees'],
            'tripId': tripId,
            'departure': trip['departure'],
            'arrival': trip['arrival'],
            'time': trip['time'],
          });
        }
      }
    }
    return requests;
  }

  static Future<int> countPendingForDriver() async {
    final requests = await getPendingRequests();
    return requests.length;
  }

  static Future<String?> getLastSeenStatus(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('res_status_$reservationId');
  }

  static Future<void> setLastSeenStatus(
    String reservationId,
    String status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('res_status_$reservationId', status);
  }
}