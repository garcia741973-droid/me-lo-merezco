import 'dart:convert';
import 'package:http/http.dart' as http;

class OffersService {
  static const String baseUrl =
      'https://me-lo-merezco-backend.onrender.com';

  static Future<List<dynamic>> fetchActiveOffers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/offers'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error cargando ofertas');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }
}