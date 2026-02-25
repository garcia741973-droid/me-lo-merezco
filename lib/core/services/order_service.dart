import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/models/order.dart';
import '../../config/api.dart';
import 'auth_service.dart';

class OrderService {
  // =====================================================
  // CLIENTE
  // =====================================================

  static Future<List<Order>> fetchClientOrders() async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error al cargar pedidos (${res.statusCode})');
    }

    final List<dynamic> data = jsonDecode(res.body);

    return data
        .map<Order>((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addQuote({
    required String productName,
    String? productUrl,
    required double basePrice,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.post(
      Uri.parse('$baseUrl/orders/add-quote'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_name': productName,
        'product_url': productUrl,
        'base_price': basePrice,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Error agregando cotización (${res.statusCode})');
    }
  }

  static Future<void> deleteOrderItem(int itemId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.delete(
      Uri.parse('$baseUrl/order-items/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error eliminando item (${res.statusCode})');
    }
  }

  static Future<Order> fetchOrder(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error al obtener pedido');
    }

    return Order.fromJson(jsonDecode(res.body));
  }

  static Future<List<dynamic>> fetchOrderItems(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error al obtener items (${res.statusCode})');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> requestOrderValidation(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error solicitando validación (${res.statusCode})');
    }
  }

// =====================================================
// CLIENTE – RECALCULAR QUOTES ANTES DE ENVIAR
// =====================================================

static Future<double> recalculateQuotes(int orderId) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.patch(
    Uri.parse('$baseUrl/orders/$orderId/recalculate-quotes'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error recalculando cotizaciones (${res.statusCode})');
  }

  final data = jsonDecode(res.body);

  final raw = data['new_total'];

  if (raw == null) {
    throw Exception('Respuesta inválida del servidor');
  }

  return double.parse(raw.toString());
}



  // =====================================================
  // ADMIN – PENDIENTES
  // =====================================================

  static Future<int> fetchPendingOrdersCount() async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/orders/admin/pending'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error cargando pendientes');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.length;
  }

  // =====================================================
  // ADMIN – APROBAR / RECHAZAR ITEM
  // =====================================================

  static Future<void> approveItem(int itemId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/order-items/$itemId/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error aprobando item');
    }
  }

  static Future<void> rejectItem(int itemId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/order-items/$itemId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error rechazando item');
    }
  }

// =====================================================
// CLIENTE – ENVIAR ITEM A VALIDACIÓN
// =====================================================

static Future<void> requestItemValidation(int itemId) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.patch(
    Uri.parse('$baseUrl/order-items/$itemId/request'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception(
      'Error enviando item para validación (${res.statusCode})',
    );
  }
}


  // =====================================================
  // SELLER – RESUMEN
  // =====================================================

  static Future<Map<String, dynamic>> fetchSellerSummary() async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('No autenticado');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/orders/seller/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error cargando resumen vendedor');
    }

    return jsonDecode(res.body);
  }

  // =====================================================
  // CLIENTE – MARCAR PAGO ENVIADO
  // =====================================================

  static Future<void> markPaymentSent(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/payment-sent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error enviando pago (${res.statusCode})');
    }
  }

  // =====================================================
  // ADMIN – CONFIRMAR PAGO
  // =====================================================

  static Future<void> confirmPayment(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/confirm-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error confirmando pago (${res.statusCode})');
    }
  }

  // =====================================================
  // SELLER / ADMIN – MARCAR ENTREGADO
  // =====================================================

  static Future<void> markDelivered(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/mark-delivered'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error marcando entregado (${res.statusCode})');
    }
  }
}
