import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PaymentQrService {

  static const _baseUrl =
      'https://me-lo-merezco-backend.onrender.com/admin/payment-qrs';

  // =========================
  // LISTAR QRs
  // =========================

  static Future<List<dynamic>> fetchQrs() async {

    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token'
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error obteniendo QRs');
    }

    return jsonDecode(res.body);
  }

  // =========================
  // CREAR QR
  // =========================

  static Future<void> createQr({
    required String qrUrl,
    required double percent,
    required DateTime validFrom,
    required DateTime validUntil,
  }) async {

    final token = await AuthService().getToken();

    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        "qr_image_url": qrUrl,
        "first_payment_percent": percent,
        "valid_from": validFrom.toIso8601String(),
        "valid_until": validUntil.toIso8601String(),
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Error creando QR');
    }
  }

  // =========================
  // ACTIVAR QR
  // =========================

  static Future<void> activateQr(int id) async {

    final token = await AuthService().getToken();

    final res = await http.patch(
      Uri.parse("$_baseUrl/$id/activate"),
      headers: {
        'Authorization': 'Bearer $token'
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error activando QR');
    }
  }

  // =========================
  // ELIMINAR QR
  // =========================

  static Future<void> deleteQr(int id) async {

    final token = await AuthService().getToken();

    final res = await http.delete(
      Uri.parse("$_baseUrl/$id"),
      headers: {
        'Authorization': 'Bearer $token'
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error eliminando QR');
    }
  }
}