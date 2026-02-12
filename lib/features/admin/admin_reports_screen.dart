import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool loading = true;
  Map<String, dynamic>? summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final token = await AuthService().getToken();
      final res = await http.get(
        Uri.parse(
          'https://me-lo-merezco-backend.onrender.com/admin/reports/summary',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          summary = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : summary == null
              ? const Center(
                  child: Text('No se pudieron cargar los informes'),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _card(
                        title: 'Ventas totales',
                        value:
                            '\$${summary!['total_sales'].toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                      ),
                      const SizedBox(height: 16),
                      _card(
                        title: 'Pedidos totales',
                        value:
                            summary!['total_orders'].toString(),
                        icon: Icons.shopping_cart,
                      ),
                      const SizedBox(height: 16),
                      _card(
                        title: 'Pedidos aprobados',
                        value:
                            summary!['approved_orders'].toString(),
                        icon: Icons.check_circle,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _card({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, size: 36),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
