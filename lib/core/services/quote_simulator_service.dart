import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api.dart';
import 'auth_service.dart';

class QuoteSimulatorService {

  static Future<Map<String, dynamic>> fetchConfig() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http.get(
      Uri.parse('$baseUrl/admin/quote-simulator-config'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

print("STATUS CODE CONFIG: ${res.statusCode}");
print("BODY CONFIG: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('Error cargando configuración');
    }

    return jsonDecode(res.body);
  }
}