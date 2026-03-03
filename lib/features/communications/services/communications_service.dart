import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/services/auth_service.dart';
import '../models/admin_message.dart';

class CommunicationsService {

  static const _baseUrl =
      'https://me-lo-merezco-backend.onrender.com';

  // =========================
  // GET MENSAJES
  // =========================
  static Future<List<AdminMessage>> getMessages(
      int otherUserId) async {

    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.get(
      Uri.parse('$_baseUrl/communications/$otherUserId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      await AuthService().logout();
      throw Exception('Sesión expirada');
    }

    if (res.statusCode != 200) {
      throw Exception('Error cargando mensajes (${res.statusCode})');
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => AdminMessage.fromJson(e)).toList();
  }

  // =========================
  // ENVIAR MENSAJE
  // =========================
  static Future<void> sendMessage({
    int? receiverId,
    String? roleTarget,
    required String message,
  }) async {

    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.post(
      Uri.parse('$_baseUrl/communications/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (receiverId != null) 'receiverId': receiverId,
        if (roleTarget != null) 'roleTarget': roleTarget,
        'message': message,
      }),
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      await AuthService().logout();
      throw Exception('Sesión expirada');
    }

    if (res.statusCode != 200) {
      throw Exception('Error enviando mensaje (${res.statusCode})');
    }
  }

// =========================
// ADMIN - LISTA CONVERSACIONES
// =========================
static Future<List<Map<String, dynamic>>> getAdminConversations() async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.get(
    Uri.parse('$_baseUrl/communications/admin/list'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode == 401 || res.statusCode == 403) {
    await AuthService().logout();
    throw Exception('Sesión expirada');
  }

  if (res.statusCode != 200) {
    throw Exception('Error cargando conversaciones');
  }

  final List data = jsonDecode(res.body);
  return data.cast<Map<String, dynamic>>();
}

}