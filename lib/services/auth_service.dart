import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'error_utils.dart';
import 'vehicle_service.dart';

enum AuthStatus { success, twoFactorRequired, failure }

class AuthResult {
  final AuthStatus status;
  final String? message;
  final String? token;
  final bool isAuthError;

  const AuthResult({
    required this.status,
    this.message,
    this.token,
    this.isAuthError = false,
  });

  bool get success => status == AuthStatus.success;
  bool get twoFactorRequired => status == AuthStatus.twoFactorRequired;

  factory AuthResult.success({String? token}) {
    return AuthResult(status: AuthStatus.success, token: token);
  }

  factory AuthResult.twoFactor({String? message}) {
    return AuthResult(status: AuthStatus.twoFactorRequired, message: message);
  }

  factory AuthResult.failure(String message, {bool isAuthError = false}) {
    return AuthResult(
      status: AuthStatus.failure,
      message: message,
      isAuthError: isAuthError,
    );
  }
}

class AuthService {
  static final Uri _loginUrl = Uri.parse('${ApiConstants.baseUrl}/auth/login');
  static final Uri _twoFaUrl = Uri.parse('${ApiConstants.baseUrl}/auth/login/2fa');
  static final Uri _registerUrl = Uri.parse('${ApiConstants.baseUrl}/auth/register');
  static final Uri _forgotUrl = Uri.parse('${ApiConstants.baseUrl}/auth/forgot-password');
  static final Uri _resetUrl = Uri.parse('${ApiConstants.baseUrl}/auth/reset-password');
  static final Uri _meUrl = Uri.parse('${ApiConstants.baseUrl}/users/me');

  static const Duration _timeout = Duration(seconds: 12);
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http
          .post(
            _loginUrl,
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      final body = _tryDecode(response.body);

      if (response.statusCode == 200) {
        if (body != null && body['twoFactorRequired'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          return AuthResult.twoFactor(
            message: body['message'] ??
                'Un code 2FA a ete envoye sur votre adresse email.',
          );
        }
        final token = body?['token'];
        if (token is String && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt', token);
          await prefs.setString('email', email);
          await fetchAndStoreCurrentUser();
          return AuthResult.success(token: token);
        }
        return AuthResult.failure('Reponse inattendue du serveur.');
      }

      logNetworkError('AuthService.login', response);
      return AuthResult.failure(
        extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return AuthResult.failure(
        'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return AuthResult.failure(
        'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AuthResult.failure('Une erreur est survenue: ${e.toString()}');
    }
  }

  static Future<AuthResult> verifyTwoFactor(String email, String code) async {
    try {
      final response = await http
          .post(
            _twoFaUrl,
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'code': code}),
          )
          .timeout(_timeout);

      final body = _tryDecode(response.body);

      if (response.statusCode == 200) {
        final token = body?['token'];
        if (token is String && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt', token);
          await prefs.setString('email', email);
          await fetchAndStoreCurrentUser();
          return AuthResult.success(token: token);
        }
        return AuthResult.failure('Reponse inattendue du serveur.');
      }

      logNetworkError('AuthService.verifyTwoFactor', response);
      return AuthResult.failure(
        extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return AuthResult.failure(
        'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return AuthResult.failure(
        'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AuthResult.failure('Une erreur est survenue: ${e.toString()}');
    }
  }

  static Future<AuthResult> register(Map<String, dynamic> payload) async {
    try {
      final nom = payload['lastName'] ?? payload['nom'] ?? '';
      final prenom = payload['firstName'] ?? payload['prenom'] ?? '';
      final email = payload['email'] ?? '';
      final password = payload['password'] ?? '';
      final telephone = payload['phone'] ?? payload['telephone'] ?? '';

      final response = await http
          .post(
            _registerUrl,
            headers: _jsonHeaders,
            body: jsonEncode({
              'nom': nom,
              'prenom': prenom,
              'email': email,
              'password': password,
              'telephone': telephone,
            }),
          )
          .timeout(_timeout);

      final body = _tryDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        logNetworkError('AuthService.register', response);
        return AuthResult.failure(
          extractErrorMessage(response),
          isAuthError: response.statusCode == 401,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firstName', prenom);
      await prefs.setString('lastName', nom);
      await prefs.setString('email', email);
      await prefs.setString('phone', telephone);
      if (payload['studentCardName'] is String) {
        await prefs.setString('studentCardName', payload['studentCardName']);
      }

      if (password.isEmpty) {
        return AuthResult.failure(
          'Compte cree, mais connexion automatique impossible.',
        );
      }

      return login(email, password);
    } on SocketException {
      return AuthResult.failure(
        'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return AuthResult.failure(
        'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AuthResult.failure('Une erreur est survenue: ${e.toString()}');
    }
  }

  static Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            _forgotUrl,
            headers: _jsonHeaders,
            body: jsonEncode({'email': email}),
          )
          .timeout(_timeout);

      final body = _tryDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          status: AuthStatus.success,
          message: body?['message'] ?? 'Email envoye.',
        );
      }

      logNetworkError('AuthService.forgotPassword', response);
      return AuthResult.failure(extractErrorMessage(response));
    } on SocketException {
      return AuthResult.failure(
        'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return AuthResult.failure(
        'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AuthResult.failure('Une erreur est survenue: ${e.toString()}');
    }
  }

  static Future<AuthResult> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            _resetUrl,
            headers: _jsonHeaders,
            body: jsonEncode({'token': token, 'newPassword': newPassword}),
          )
          .timeout(_timeout);

      final body = _tryDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          status: AuthStatus.success,
          message: body?['message'] ?? 'Mot de passe reinitialise.',
        );
      }

      logNetworkError('AuthService.resetPassword', response);
      return AuthResult.failure(extractErrorMessage(response));
    } on SocketException {
      return AuthResult.failure(
        'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return AuthResult.failure(
        'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AuthResult.failure('Une erreur est survenue: ${e.toString()}');
    }
  }

  static Future<void> fetchAndStoreCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return;
      final response = await http.get(
        _meUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode != 200) {
        logNetworkError('AuthService.fetchAndStoreCurrentUser', response);
        return;
      }
      final body = _tryDecode(response.body);
      if (body == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (body['id'] != null) {
        final id = body['id'] is int
            ? body['id'] as int
            : int.tryParse(body['id'].toString()) ?? 0;
        await prefs.setInt('userId', id);
      }
      if (body['prenom'] is String) {
        await prefs.setString('firstName', body['prenom']);
      }
      if (body['nom'] is String) {
        await prefs.setString('lastName', body['nom']);
      }
      if (body['email'] is String) {
        await prefs.setString('email', body['email']);
      }
      if (body['telephone'] is String) {
        await prefs.setString('phone', body['telephone']);
      }

      final backendRole = body['role'];
      if (backendRole is String) {
        await prefs.setString('backendRole', backendRole);
      }

      if (backendRole == 'ROLE_ADMIN') {
        return;
      }

      final hasVehicle = await VehicleService.hasVehicle();
      await prefs.setString('role', hasVehicle ? 'driver' : 'passenger');
    } catch (_) {
      // si ca rate on garde juste les infos locales telles quelles
    }
  }

  static Future<AuthResult> updateCurrentUser(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return AuthResult.failure(
          'Session expiree, reconnectez-vous.',
          isAuthError: true,
        );
      }
      final response = await http
          .put(
            _meUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final body = _tryDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (body?['prenom'] is String) {
          await prefs.setString('firstName', body!['prenom']);
        } else if (payload['prenom'] is String) {
          await prefs.setString('firstName', payload['prenom']);
        }
        if (body?['nom'] is String) {
          await prefs.setString('lastName', body!['nom']);
        } else if (payload['nom'] is String) {
          await prefs.setString('lastName', payload['nom']);
        }
        if (body?['telephone'] is String) {
          await prefs.setString('phone', body!['telephone']);
        } else if (payload['telephone'] is String) {
          await prefs.setString('phone', payload['telephone']);
        }
        return AuthResult.success();
      }

      logNetworkError('AuthService.updateCurrentUser', response);
      return AuthResult.failure(
        extractErrorMessage(response),
        isAuthError: response.statusCode == 401,
      );
    } on SocketException {
      return AuthResult.failure(
        'Impossible de contacter le serveur. Verifiez votre connexion.',
      );
    } on TimeoutException {
      return AuthResult.failure(
        'Le serveur met trop de temps a repondre. Reessayez.',
      );
    } catch (e) {
      return AuthResult.failure('Une erreur est survenue: ${e.toString()}');
    }
  }

  static Map<String, dynamic>? _tryDecode(String raw) {
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    await prefs.remove('userId');
    await prefs.remove('firstName');
    await prefs.remove('lastName');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('role');
    await prefs.remove('backendRole');
    await prefs.remove('profilePhotoUrl');
    await prefs.remove('studentCardName');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    return (id != null && id > 0) ? id : null;
  }

  static Future<String> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firstName') ?? '';
  }

  static Future<String> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastName') ?? '';
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  static Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone') ?? '';
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') ?? 'passenger';
  }

  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final backendRole = prefs.getString('backendRole') ?? '';
    return backendRole == 'ROLE_ADMIN';
  }

  static Future<String> getProfilePhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profilePhotoUrl') ?? '';
  }

  static Future<void> saveProfilePhotoUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profilePhotoUrl', url);
  }
}