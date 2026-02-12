import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://me-lo-merezco-backend.onrender.com';

Future<void> testBackendApi() async {
  print('🚀 testBackendApi ejecutándose');

  // -------------------------
  // 1️⃣ GET /orders/1
  // -------------------------
  final orderUrl = Uri.parse('$baseUrl/orders/1');
  final orderResponse = await http.get(orderUrl);

  print('🧾 ORDER status: ${orderResponse.statusCode}');
  print('🧾 ORDER body: ${orderResponse.body}');

  // -------------------------
  // 2️⃣ GET /orders/1/items
  // -------------------------
  final itemsUrl = Uri.parse('$baseUrl/orders/1/items');
  final itemsResponse = await http.get(itemsUrl);

  print('📦 ITEMS status: ${itemsResponse.statusCode}');
  print('📦 ITEMS body: ${itemsResponse.body}');

  // -------------------------
  // 3️⃣ PATCH /order-items/3/approve
  // (elige un item pendiente)
  // -------------------------
  final approveUrl =
      Uri.parse('$baseUrl/order-items/3/approve');

  final approveResponse = await http.patch(approveUrl);

  print('✅ APPROVE status: ${approveResponse.statusCode}');
  print('✅ APPROVE body: ${approveResponse.body}');
}
