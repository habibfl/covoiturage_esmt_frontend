import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'auth_service.dart';
import 'error_utils.dart';

class AvisResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? avis;
  final bool isAuthError;

  const AvisResult({
    required this.success,
    this.message,
    this.avis,
    this.isAuthError = false,
  });
}

class AvisService {
  static Future<AvisResult> createAvis({
    required String reservationId,
    required String cibleId,
    required int note,
    String? commentaire,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const AvisResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/avis');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'reservationId': int.tryParse(reservationId) ?? reservationId,
              'cibleId': int.tryParse(cibleId) ?? cibleId,
              'note': note,
              'commentaire': commentaire ?? '',
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic>? body;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) body = decoded;
        } catch (_) {}
        await _markReviewed(reservationId);
        return AvisResult(success: true, avis: body);
      }

      logNetworkError('AvisService.createAvis', response);
      return AvisResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return const AvisResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const AvisResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AvisResult(success: false, message: 'Erreur: $e');
    }
  }

  static Future<double> getNoteMoyenne(String userId) async {
    final data = await _getMoyenneData(userId);
    final moyenne = data?['moyenne'];
    if (moyenne is num) return moyenne.toDouble();
    return 0.0;
  }

  static Future<int> getNombreAvis(String userId) async {
    final data = await _getMoyenneData(userId);
    final nombre = data?['nombreAvis'];
    if (nombre is num) return nombre.toInt();
    return 0;
  }

  static Future<Map<String, dynamic>?> _getMoyenneData(String userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/avis/utilisateur/$userId/moyenne',
      );
      final response = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (e) {
      logSilentError('AvisService._getMoyenneData', e);
      return null;
    }
  }

  static Future<bool> hasReviewed(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('avis_done_$reservationId') ?? false;
  }

  static Future<void> _markReviewed(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('avis_done_$reservationId', true);
  }
}