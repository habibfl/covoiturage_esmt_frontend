import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'auth_service.dart';
import 'error_utils.dart';

class AdminResult {
  final bool success;
  final String? message;

  const AdminResult({required this.success, this.message});
}

class AdminService {
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return [];
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/users');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        logNetworkError('AdminService.getAllUsers', response);
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<AdminResult> blockUser(String userId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const AdminResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/users/$userId/block');
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return const AdminResult(success: true);
      }
      logNetworkError('AdminService.blockUser', response);
      return AdminResult(success: false, message: extractErrorMessage(response));
    } on SocketException {
      return const AdminResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const AdminResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AdminResult(success: false, message: 'Erreur: $e');
    }
  }

  static Future<AdminResult> unblockUser(String userId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const AdminResult(
        success: false,
        message: 'Vous devez etre connecte.',
      );
    }
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/users/$userId/unblock');
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return const AdminResult(success: true);
      }
      logNetworkError('AdminService.unblockUser', response);
      return AdminResult(success: false, message: extractErrorMessage(response));
    } on SocketException {
      return const AdminResult(
        success: false,
        message: 'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return const AdminResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AdminResult(success: false, message: 'Erreur: $e');
    }
  }
}