import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'auth_service.dart';
import 'error_utils.dart';

class VehicleResult {
  final bool success;
  final String? message;
  final bool isAuthError;

  const VehicleResult({
    required this.success,
    this.message,
    this.isAuthError = false,
  });
}

class VehicleService {
  static Future<VehicleResult> addVehicle({
    required String marque,
    required String modele,
    required String immatriculation,
    required String couleur,
    required int nombrePlacesTotales,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const VehicleResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }

    final userId = await AuthService.getUserId();
    if (userId == null) {
      return const VehicleResult(
        success: false,
        message:
            'Impossible de recuperer votre identifiant utilisateur. Reconnectez-vous.',
        isAuthError: true,
      );
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/vehicules');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'marque': marque,
              'modele': modele,
              'matricule': immatriculation,
              'couleur': couleur,
              'nbPlaces': nombrePlacesTotales,
              'utilisateurId': userId,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const VehicleResult(success: true);
      }

      logNetworkError('VehicleService.addVehicle', response);
      return VehicleResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return const VehicleResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const VehicleResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return VehicleResult(
        success: false,
        message: 'Une erreur est survenue: $e',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchOwnedVehicles() async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();
    if (token == null || userId == null) return [];
    try {
      final uri =
          Uri.parse('${ApiConstants.baseUrl}/vehicules/proprietaire/$userId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        logNetworkError('VehicleService._fetchOwnedVehicles', response);
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      logSilentError('VehicleService._fetchOwnedVehicles', e);
      return [];
    }
  }

  static Future<bool> hasVehicle() async {
    final vehicles = await _fetchOwnedVehicles();
    return vehicles.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getMyVehicle() async {
    final vehicles = await _fetchOwnedVehicles();
    return vehicles.isEmpty ? null : vehicles.first;
  }
}