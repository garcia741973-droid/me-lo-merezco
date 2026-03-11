import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AdminService {

  static const _baseUrl = 'https://me-lo-merezco-backend.onrender.com';

  // =====================================
  // LISTAR ADMINISTRADORES
  // =====================================

  static Future<List<dynamic>> fetchAdmins() async {

    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse('$_baseUrl/admin/admins'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error cargando administradores');
    }

    return jsonDecode(res.body);
  }

  // =====================================
  // CREAR ADMIN
  // =====================================

  static Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {

    final token = await AuthService().getToken();

    final res = await http.post(
      Uri.parse('$_baseUrl/admin/admins'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Error creando administrador");
    }
  }

  // =====================================
  // EDITAR ADMIN
  // =====================================

  static Future<void> editAdmin({
    required int id,
    required String name,
    required String email,
  }) async {

    final token = await AuthService().getToken();

    final res = await http.put(
      Uri.parse('$_baseUrl/admin/admins/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Error actualizando administrador");
    }
  }

  // =====================================
  // ACTIVAR ADMIN
  // =====================================

  static Future<void> activateAdmin(int id) async {

    final token = await AuthService().getToken();

    final res = await http.patch(
      Uri.parse('$_baseUrl/admin/admins/$id/activate'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Error activando administrador");
    }
  }

  // =====================================
  // DESACTIVAR ADMIN
  // =====================================

  static Future<void> deactivateAdmin(int id) async {

    final token = await AuthService().getToken();

    final res = await http.patch(
      Uri.parse('$_baseUrl/admin/admins/$id/deactivate'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Error desactivando administrador");
    }
  }

  // =====================================
  // RESET PASSWORD ADMIN
  // =====================================

  static Future<void> resetPassword({
    required int id,
    required String newPassword,
  }) async {

    final token = await AuthService().getToken();

    final res = await http.patch(
      Uri.parse('$_baseUrl/admin/admins/$id/reset-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'newPassword': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Error cambiando contraseña");
    }
  }

  // =====================================
  // ELIMINAR ADMIN
  // =====================================

  static Future<void> deleteAdmin(int id) async {

    final token = await AuthService().getToken();

    final res = await http.delete(
      Uri.parse('$_baseUrl/admin/admins/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Error eliminando administrador");
    }
  }

}