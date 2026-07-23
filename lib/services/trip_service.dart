import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'auth_service.dart';
import 'error_utils.dart';

class TripPublishResult {
  final bool success;
  final String? message;
  final bool isAuthError;

  const TripPublishResult({
    required this.success,
    this.message,
    this.isAuthError = false,
  });
}

class TripService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getTrajets({
    String? depart,
    String? arrivee,
  }) async {
    try {
      final query = <String, String>{};
      if (depart != null && depart.isNotEmpty) query['depart'] = depart;
      if (arrivee != null && arrivee.isNotEmpty) query['arrivee'] = arrivee;
      final uri = Uri.parse('${ApiConstants.baseUrl}/trajets').replace(
        queryParameters: query.isEmpty ? null : query,
      );
      final response = await http
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        logNetworkError('TripService.getTrajets', response);
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      final results = <Map<String, dynamic>>[];
      for (final item in decoded.whereType<Map<String, dynamic>>()) {
        results.add(await _mapTrajet(item));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getTrajetById(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/trajets/$id');
      final response = await http
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        logNetworkError('TripService.getTrajetById', response);
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return _mapTrajet(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getTrajetsByConducteur(
    int conducteurId,
  ) async {
    try {
      final uri =
          Uri.parse('${ApiConstants.baseUrl}/trajets/conducteur/$conducteurId');
      final response = await http
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        logNetworkError('TripService.getTrajetsByConducteur', response);
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded.whereType<Map<String, dynamic>>().map((json) {
        return {
          'id': json['id'],
          'departure': json['pointDepart'],
          'arrival': json['pointArrivee'],
          'dateDepart': json['dateDepart'],
          'time': json['heureDepart'],
          'seats': json['nbPlacesDisponibles'],
          'conducteurId': json['conducteurId'],
          'statut': json['statutTrajet'],
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<TripPublishResult> updateTripStatus(
    String tripId,
    String newStatus,
  ) async {
    final existing = await getTrajetById(tripId);
    if (existing == null) {
      return const TripPublishResult(
        success: false,
        message: 'Trajet introuvable.',
      );
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const TripPublishResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/trajets/$tripId');
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'pointDepart': existing['departure'],
              'pointArrivee': existing['arrival'],
              'dateDepart': existing['dateDepart'],
              'heureDepart': existing['time'],
              'nbPlacesDisponibles': existing['seats'],
              'conducteurId': existing['conducteurId'],
              'statutTrajet': newStatus,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return const TripPublishResult(success: true);
      }

      logNetworkError('TripService.updateTripStatus', response);
      return TripPublishResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } catch (e) {
      return TripPublishResult(success: false, message: 'Erreur: $e');
    }
  }

  static Future<Map<String, dynamic>> _mapTrajet(
    Map<String, dynamic> json,
  ) async {
    final driverName = json['conducteurNom']?.toString();
    final conducteurId = json['conducteurId'];

    String? vehicle;
    if (conducteurId != null) {
      vehicle = await _fetchVehicleLabel(conducteurId);
    }

    return {
      'id': json['id'],
      'driverName': driverName,
      'vehicle': vehicle,
      'departure': json['pointDepart'],
      'arrival': json['pointArrivee'],
      'dateDepart': json['dateDepart'],
      'time': json['heureDepart'],
      'seats': json['nbPlacesDisponibles'],
      'conducteurId': conducteurId,
      'price': null,
      'statut': json['statutTrajet'],
      'latDepart': json['latDepart'],
      'lngDepart': json['lngDepart'],
      'latArrivee': json['latArrivee'],
      'lngArrivee': json['lngArrivee'],
    };
  }

  static Future<String?> _fetchVehicleLabel(dynamic conducteurId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/vehicules/proprietaire/$conducteurId',
      );
      final response = await http
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is! Map<String, dynamic>) return null;
      final marque = first['marque'] ?? '';
      final modele = first['modele'] ?? '';
      final label = ('$marque $modele').trim();
      return label.isEmpty ? null : label;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> reserverPlace(int trajetId, {int nbPlaces = 1}) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/reservations');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'trajetId': trajetId,
              'nbPlacesReservees': nbPlaces,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200 && response.statusCode != 201) {
        logNetworkError('TripService.reserverPlace', response);
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<TripPublishResult> publierTrajet(
    Map<String, dynamic> data,
  ) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const TripPublishResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }

    final userId = await AuthService.getUserId();
    if (userId == null) {
      return const TripPublishResult(
        success: false,
        message:
            'Impossible de recuperer votre identifiant utilisateur. Reconnectez-vous.',
        isAuthError: true,
      );
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/trajets');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              ...data,
              'conducteurId': userId,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const TripPublishResult(success: true);
      }

      logNetworkError('TripService.publierTrajet', response);
      return TripPublishResult(
        success: false,
        message: extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } catch (e) {
      return TripPublishResult(
        success: false,
        message: 'Une erreur est survenue: $e',
      );
    }
  }
}