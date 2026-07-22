import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'auth_service.dart';
import 'error_utils.dart';

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
      final active = decoded.cast<Map<String, dynamic>>().firstWhere(
            (r) =>
                r['statutReservation'] == 'EN_ATTENTE' ||
                r['statutReservation'] == 'CONFIRMEE',
            orElse: () => {},
          );
      return active.isEmpty ? null : active;
    } catch (_) {
      return null;
    }
  }
}