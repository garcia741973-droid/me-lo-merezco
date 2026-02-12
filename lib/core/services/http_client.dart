import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class HttpClient {
  static const baseUrl = 'https://me-lo-merezco-backend.onrender.com';

  static Future<http.Response> get(String path) async {
    final token = await AuthService().getToken();
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );
  }

  static Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final token = await AuthService().getToken();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    final token = await AuthService().getToken();
    return http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
