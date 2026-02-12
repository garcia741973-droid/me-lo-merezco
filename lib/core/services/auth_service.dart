import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

    // ❌ Credenciales incorrectas
    if (res.statusCode == 401 || res.statusCode == 403) {
      return false;
    }

    // ❌ Error real
    if (res.statusCode != 200) {
      throw Exception('Error del servidor (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, data['token']);

    _currentUser = _userFromJson(data['user']);

    return true;
  }

  // =========================
  // REGISTER (SIEMPRE CLIENTE)
  // =========================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    int? sellerId, // 👈 NUEVO (opcional)
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (sellerId != null) 'seller_id': sellerId, // 👈 NUEVO
      }),
    );

    // ❌ Email ya existe
    if (res.statusCode == 409) {
      return false;
    }
// 👇 LOGS DE DEBUG (CORRECTAMENTE DENTRO DEL MÉTODO)
  print('REGISTER STATUS: ${res.statusCode}');
  print('REGISTER BODY: ${res.body}');


    // ❌ Error real
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error del servidor (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, data['token']);

    _currentUser = _userFromJson(data['user']);

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

    // Token inválido o expirado
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _currentUser = null;
  }

// =========================
// CHANGE PASSWORD (USUARIO LOGUEADO)
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

  // ❌ Contraseña actual incorrecta
  if (res.statusCode == 400) {
    return false;
  }

  // ❌ Token inválido o expirado
  if (res.statusCode == 401 || res.statusCode == 403) {
    await logout();
    throw Exception('Sesión expirada');
  }

  // ❌ Error real
  if (res.statusCode != 200) {
    throw Exception('Error del servidor (${res.statusCode})');
  }

  // ✅ OK
  return true;
}


  // =========================
  // SELLER HELPERS (SE MANTIENEN)
  // =========================
  int getAssociatedClientsCount() => 0;

  String? getAssociatedSellerEmail() {
    return _currentUser?.email;
  }

  Map<String, dynamic>? getSellerByEmail(String? email) {
    if (email == null) return null;

    return {
      'email': email,
      'name': _currentUser?.name ?? '',
    };
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
