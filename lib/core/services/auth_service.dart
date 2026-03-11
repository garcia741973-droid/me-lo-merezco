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

 print("LOGIN STATUS: ${res.statusCode}");
print("LOGIN BODY: ${res.body}");   

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
      required String documentId,
      required String phone,
      required String birthDate,
      required String country,
      required String city,
      String? address,
      List<String>? interests,
      int? sellerId,
    }) async {

      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'document_id': documentId,
          'phone': phone,
          'birth_date': birthDate,
          'country': country,
          'city': city,
          'address': address,
          'interests': interests ?? [],
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

      await _registerDeviceToken(data['token']);

      return true;
    }

    // =========================
    // REQUEST RESET CODE
    // =========================
    Future<void> requestResetCode(String email) async {

      final res = await http.post(
        Uri.parse('$_baseUrl/auth/request-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('Error enviando código');
      }

    }

    Future<bool> verifyResetCode(String email, String code) async {

      final res = await http.post(
        Uri.parse('$_baseUrl/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      return res.statusCode == 200;

    }

    Future<bool> setNewPassword(
      String email,
      String code,
      String newPassword,
    ) async {

      final res = await http.post(
        Uri.parse('$_baseUrl/auth/set-new-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );

      return res.statusCode == 200;

    }


  // =========================
  // RESTAURAR SESIÓN (APP START)
  // =========================
Future<bool> fetchCurrentUserFromToken() async {
  final token = await getToken();
  if (token == null) return false;

  try {
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

    // 🔐 Solo cerrar sesión si el backend confirma 401 real
    if (res.statusCode == 401 || res.statusCode == 403) {
      print("⚠️ Token inválido confirmado por backend");
      await logout();
      return false;
    }

    // Otros códigos no deben hacer logout automático
    print("⚠️ Código inesperado: ${res.statusCode}");
    return true;

  } catch (e) {
    // 🚨 ERROR DE RED (ej: Render dormido)
    print("⚠️ Error de red al verificar sesión: $e");
    // NO hacer logout
    return true;
  }
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