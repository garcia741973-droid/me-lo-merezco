import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../shared/models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _baseUrl = 'https://me-lo-merezco-backend.onrender.com';
  static const _tokenKey = 'auth_token';

  User? _currentUser;
  User? get currentUser => _currentUser;

  // =========================
  // LOGIN REAL (JWT)
  // =========================
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      return false;
    }

    if (res.statusCode != 200) {
      throw Exception('Error del servidor (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, data['token']);
    _currentUser = _userFromJson(data['user']);

    // 🔔 Registrar FCM token automáticamente
    await _registerDeviceToken(data['token']);

    return true;
  }

  // =========================
  // REGISTER (SIEMPRE CLIENTE)
  // =========================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    int? sellerId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (sellerId != null) 'seller_id': sellerId,
      }),
    );

    if (res.statusCode == 409) {
      return false;
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error del servidor (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, data['token']);
    _currentUser = _userFromJson(data['user']);

    // 🔔 Registrar FCM token automáticamente
    await _registerDeviceToken(data['token']);

    return true;
  }

  // =========================
  // RESTAURAR SESIÓN (APP START)
  // =========================
  Future<bool> fetchCurrentUserFromToken() async {
    final token = await getToken();
    if (token == null) return false;

    final res = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _currentUser = _userFromJson(data);
      return true;
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      await logout();
      return false;
    }

    throw Exception('Error verificando sesión (${res.statusCode})');
  }

  // =========================
  // TOKEN
  // =========================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    final token = await getToken();

    if (token != null) {
      await _removeDeviceToken(token);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _currentUser = null;
  }

  // =========================
  // CHANGE PASSWORD
  // =========================
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (res.statusCode == 400) {
      return false;
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      await logout();
      throw Exception('Sesión expirada');
    }

    if (res.statusCode != 200) {
      throw Exception('Error del servidor (${res.statusCode})');
    }

    return true;
  }

  // =========================
  // DEVICE TOKEN MANAGEMENT
  // =========================

  Future<void> _registerDeviceToken(String jwt) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      await http.post(
        Uri.parse('$_baseUrl/devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': 'ios',
        }),
      );
    } catch (e) {
      print('Error registrando device token: $e');
    }
  }

  Future<void> _removeDeviceToken(String jwt) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      await http.delete(
        Uri.parse('$_baseUrl/devices/current'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );
    } catch (e) {
      print('Error eliminando device token: $e');
    }
  }

  // =========================
  // PRIVATE HELPERS
  // =========================

  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
      ),
    );
  }
}