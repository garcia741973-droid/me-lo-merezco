import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/models/order.dart';
import '../../config/api.dart';
import 'auth_service.dart';

class OrderService {
  // =====================================================
  // CLIENTE
  // =====================================================

  /// 🔹 Obtener pedidos del cliente logueado
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

    print('ORDERS STATUS: ${res.statusCode}');
    print('ORDERS BODY: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Error al cargar pedidos (${res.statusCode})');
    }

    final List<dynamic> data = jsonDecode(res.body);

    return data
        .map<Order>((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 🔹 Agregar cotización directamente al backend (nuevo)
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

  print('ADD QUOTE STATUS: ${res.statusCode}');
  print('ADD QUOTE BODY: ${res.body}');

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

  static Future<bool> createOrderFromIntentions() async {
    final token = await AuthService().getToken();
    if (token == null) {
      return false;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/orders/from-intentions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return res.statusCode == 201;
  }

  /// 🔹 Obtener un pedido por ID
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

  /// 🔹 Obtener ítems de un pedido
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

    print('ITEMS STATUS: ${res.statusCode}');
    print('ITEMS BODY: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Error al obtener items (${res.statusCode})');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // =====================================================
  // ADMIN
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
      throw Exception('Error al cargar pendientes');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.length;
  }

  // =====================================================
  // SELLER / ADMIN – ACCIONES SOBRE ITEMS
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

  /// 🔹 Cliente solicita validación del carrito
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
}
