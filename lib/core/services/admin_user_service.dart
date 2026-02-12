import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AdminUserService {
  static const String baseUrl =
      'https://me-lo-merezco-backend.onrender.com';

  // ================================
  // HEADERS CON JWT
  // ================================
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService().getToken();

    if (token == null) {
      throw Exception('No autenticado');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ================================
  // LISTAR USUARIOS
  // GET /admin/users
  // ================================
  static Future<List<dynamic>> fetchUsers() async {
    final headers = await _authHeaders();

    final res = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: headers,
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Sesión expirada');
    }

    if (res.statusCode != 200) {
      throw Exception('Error al cargar usuarios');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // ================================
  // ACTIVAR / DESACTIVAR USUARIO
  // PATCH /admin/users/:id/status
  // ================================
  static Future<void> setActive({
    required int userId,
    required bool isActive,
  }) async {
    final headers = await _authHeaders();

    final res = await http.patch(
      Uri.parse('$baseUrl/admin/users/$userId/status'),
      headers: headers,
      body: jsonEncode({'is_active': isActive}),
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Sesión expirada');
    }

    if (res.statusCode != 200) {
      throw Exception('Error al actualizar estado del usuario');
    }
  }

  // ================================
  // CREAR USUARIO
  // POST /admin/users
  // ================================
  static Future<void> createUser({
    required String name,
    required String email,
    required String role, // admin | seller | client
    double? commissionRate,
  }) async {
    final headers = await _authHeaders();

    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'role': role,
    };

    if (role == 'seller') {
      body['commission_rate'] = commissionRate ?? 0;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Sesión expirada');
    }

    if (res.statusCode != 201) {
      try {
        final data = jsonDecode(res.body);
        throw Exception(data['error'] ?? 'Error al crear usuario');
      } catch (_) {
        throw Exception('Error al crear usuario');
      }
    }
  }
}
