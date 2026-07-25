import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

String extractErrorMessage(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final msg = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    if (decoded is String && decoded.isNotEmpty) return decoded;
  } catch (_) {}
  if (response.body.isNotEmpty && response.body.length < 300) {
    return response.body;
  }
  return 'Erreur ${response.statusCode}. Veuillez reessayer.';
}

void logNetworkError(String context, http.Response response) {
  debugPrint('[$context] HTTP ${response.statusCode}: ${response.body}');
}

void showErrorSnackBar(
  BuildContext context,
  String message, {
  bool isAuthError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: isAuthError
          ? SnackBarAction(
              label: 'Se reconnecter',
              onPressed: () => context.go('/login'),
            )
          : null,
    ),
  );
}