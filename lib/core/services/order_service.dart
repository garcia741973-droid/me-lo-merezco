import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/models/order.dart';
import '../../config/api.dart';
import 'auth_service.dart';

import 'package:flutter/foundation.dart';

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

  // =====================================================
  // Obtener pagos de un pedido (admin & client)
  // =====================================================
  static Future<List<dynamic>> fetchOrderPayments(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/payments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error obteniendo pagos (${res.statusCode})');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // =====================================================
  // CLIENTE – SOLICITAR VALIDACIÓN
  // =====================================================

  static Future<void> requestOrderValidation(int orderId) async {
    // --- DIAGNÓSTICO (no cambia la lógica) ---
    print("🚨 REQUEST ORDER VALIDATION EJECUTÁNDOSE 🚨");

    final token = await AuthService().getToken();
    if (token == null) {
      print("❌ TOKEN NULL");
      throw Exception('Usuario no autenticado');
    }

    // Mostrar token y URL final para rastreo
    print("🔑 TOKEN OBTENIDO: $token");
    print("🌍 URL FINAL: $baseUrl/orders/$orderId/request");

    final res = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Imprimir respuesta para diagnóstico
    print("📡 STATUS CODE: ${res.statusCode}");
    print("📨 RESPONSE BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception(
        'Error solicitando validación (${res.statusCode})',
      );
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
// ADMIN – LISTAR TODOS LOS PEDIDOS
// =====================================================

static Future<List<Order>> fetchAdminOrders() async {
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
      print("ADMIN ERROR STATUS: ${res.statusCode}");
      print("ADMIN ERROR BODY: ${res.body}");
      throw Exception('Error cargando pedidos admin');
    }

  final List<dynamic> data = jsonDecode(res.body);

  return data
      .map<Order>((e) => Order.fromJson(e as Map<String, dynamic>))
      .toList();
}

// =====================================================
// ADMIN – ORDER DASHBOARD (NUEVO)
// =====================================================

static Future<Map<String, dynamic>> fetchAdminOrderDashboard(int orderId) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.get(
    Uri.parse('$baseUrl/admin/orders/$orderId/dashboard'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error cargando dashboard (${res.statusCode})');
  }

  return jsonDecode(res.body);
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

  // =====================================================
  // ADMIN – RECHAZO CONDICIONAL (nuevo)
  // =====================================================
static Future<void> conditionalRejectItem({
  required int itemId,
  required String message,
  double? adjustedPrice,
  List<Map<String, dynamic>>? requiredFields,
}) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.post(
    Uri.parse('$baseUrl/order-messages'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'itemId': itemId,
      'message': message,
      'adjusted_price': adjustedPrice,
      if (requiredFields != null && requiredFields.isNotEmpty)
        'required_fields': requiredFields,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Error en rechazo condicional (${res.statusCode})');
  }
}

// =====================================================
// CLIENTE – ACEPTAR CONDICIÓN (nuevo)
// =====================================================
static Future<Map<String, dynamic>> acceptOrderMessage(
  int messageId, {
  Map<String, dynamic>? filledFields,
}) async {

  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.patch(
    Uri.parse('$baseUrl/order-messages/$messageId/accept'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      if (filledFields != null && filledFields.isNotEmpty)
        'filled_fields': filledFields,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception(
      'Error aceptando condición (${res.statusCode})',
    );
  }

  return jsonDecode(res.body);
}

 // =====================================================
// CLIENTE – rechaza CONDICIÓN (nuevo)
  // =====================================================

static Future<void> rejectOrderMessage(int messageId) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.patch(
    Uri.parse('$baseUrl/order-messages/$messageId/reject'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error rechazando condición (${res.statusCode})');
  }
}

 // =====================================================
// ORDER MESSAGES
// =====================================================

static Future<List<dynamic>> fetchOrderMessages(int orderId) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.get(
    Uri.parse('$baseUrl/order-messages/order/$orderId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error cargando mensajes (${res.statusCode})');
  }

  return jsonDecode(res.body) as List<dynamic>;
}

// =====================================================
// CLIENTE – OBTENER INFO DE PAGO
// =====================================================

static Future<Map<String, dynamic>> fetchPaymentInfo(int orderId) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.get(
    Uri.parse('$baseUrl/orders/$orderId/payment-info'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error obteniendo información de pago (${res.statusCode})');
  }

  return jsonDecode(res.body);
}

// =====================================================
// CLIENTE – SUBIR COMPROBANTE (NUEVO FLUJO REAL)
// =====================================================

static Future<void> uploadProof({
  required int orderId,
  required String proofUrl,
}) async {
  final token = await AuthService().getToken();
  if (token == null) {
    throw Exception('Usuario no autenticado');
  }

  final res = await http.post(
    Uri.parse('$baseUrl/orders/$orderId/upload-proof'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'proof_url': proofUrl,
    }),
  );

  if (res.statusCode != 201) {
    throw Exception('Error enviando comprobante (${res.statusCode})');
  }
}

// =====================================================
// ADMIN – PAYMENT QR MANAGEMENT
// =====================================================

static Future<List<dynamic>> fetchAdminQrs() async {
  final token = await AuthService().getToken();
  if (token == null) throw Exception('No autenticado');

  final res = await http.get(
    Uri.parse('$baseUrl/admin/payment-qrs'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error cargando QRs');
  }

  return jsonDecode(res.body);
}

static Future<void> activateQr(int id) async {
  final token = await AuthService().getToken();
  if (token == null) throw Exception('No autenticado');

  final res = await http.patch(
    Uri.parse('$baseUrl/admin/payment-qrs/$id/activate'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error activando QR');
  }
}

static Future<void> createQr({
  required String qrUrl,
  required double percent,
  required DateTime validFrom,
  required DateTime validUntil,
}) async {
  final token = await AuthService().getToken();
  if (token == null) throw Exception('No autenticado');

  final res = await http.post(
    Uri.parse('$baseUrl/admin/payment-qrs'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'qr_image_url': qrUrl,
      'first_payment_percent': percent,
      'valid_from': validFrom.toUtc().toIso8601String(),
      'valid_until': validUntil.toUtc().toIso8601String(),
    }),
  );

  if (res.statusCode != 201) {
    throw Exception('Error creando QR');
  }
}

// =====================================================
// ADMIN – LISTADO PAGINADO
// =====================================================

static Future<List<Order>> fetchAdminOrdersFiltered({
  String? status,
  int limit = 20,
  int offset = 0,
  String? search,
}) async {
  final token = await AuthService().getToken();
  if (token == null) throw Exception('No autenticado');

  final uri = Uri.parse('$baseUrl/admin/orders').replace(
    queryParameters: {
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': limit.toString(),
      'offset': offset.toString(),
    },
  );

  final res = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Error cargando pedidos admin');
  }

  final List<dynamic> data = jsonDecode(res.body);

  return data
      .map((e) => Order.fromJson(e))
      .toList();
}


}