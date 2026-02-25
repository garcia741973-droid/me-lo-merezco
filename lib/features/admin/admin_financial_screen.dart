import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';

class AdminFinancialScreen extends StatefulWidget {
  const AdminFinancialScreen({super.key});

  @override
  State<AdminFinancialScreen> createState() =>
      _AdminFinancialScreenState();
}

class _AdminFinancialScreenState
    extends State<AdminFinancialScreen> {

  final _marginController = TextEditingController();
  final _markupController = TextEditingController();
  final _smallController = TextEditingController();
  final _mediumController = TextEditingController();
  final _largeController = TextEditingController();

  Map<String, dynamic> _rates = {};
  bool _loading = true;

  final String baseUrl =
      'https://me-lo-merezco-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await AuthService().getToken();

    try {
      final financialRes = await http.get(
        Uri.parse('$baseUrl/admin/financial-settings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final financialData =
          jsonDecode(financialRes.body);

      _marginController.text =
          financialData['margin_percent'].toString();

      _markupController.text =
          financialData['exchange_markup_percent']
              .toString();

      final importRes = await http.get(
        Uri.parse('$baseUrl/admin/import-categories'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final importData =
          jsonDecode(importRes.body);

      for (var item in importData) {
        if (item['key'] == 'small') {
          _smallController.text =
              item['percent'].toString();
        }
        if (item['key'] == 'medium') {
          _mediumController.text =
              item['percent'].toString();
        }
        if (item['key'] == 'large') {
          _largeController.text =
              item['percent'].toString();
        }
      }

      final ratesRes = await http.get(
        Uri.parse('$baseUrl/admin/exchange-rates'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final ratesList =
          jsonDecode(ratesRes.body);

      for (var r in ratesList) {
        _rates[r['currency']] = r['rate_to_bob'];
      }

      setState(() => _loading = false);

    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    final token = await AuthService().getToken();

    await http.patch(
      Uri.parse('$baseUrl/admin/financial-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'margin_percent':
            double.tryParse(_marginController.text),
        'exchange_markup_percent':
            double.tryParse(_markupController.text),
      }),
    );

    await http.patch(
      Uri.parse('$baseUrl/admin/import-categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'small':
            double.tryParse(_smallController.text),
        'medium':
            double.tryParse(_mediumController.text),
        'large':
            double.tryParse(_largeController.text),
      }),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración actualizada'),
      ),
    );

    await _loadData();
  }

  Future<void> _updateExchangeRates() async {
    final token = await AuthService().getToken();

    await http.post(
      Uri.parse('$baseUrl/exchange/update'),
      headers: {'Authorization': 'Bearer $token'},
    );

    await _loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tasas actualizadas')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Configuración Financiera'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const Text(
                'Tasas Actuales',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text('USDT → BOB: ${_rates['BOB'] ?? '-'}'),
              Text('USDT → USD: ${_rates['USD'] ?? '-'}'),
              Text('USDT → CLP: ${_rates['CLP'] ?? '-'}'),

              const Divider(height: 40),

              const Text(
                'Margen Global (%)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _marginController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              const Text(
                'Exchange Markup (%)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _markupController,
                keyboardType: TextInputType.number,
              ),

              const Divider(height: 40),

              const Text(
                'Importación por Tamaño (%)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              TextField(
                controller: _smallController,
                decoration:
                    const InputDecoration(labelText: 'Small'),
                keyboardType: TextInputType.number,
              ),

              TextField(
                controller: _mediumController,
                decoration:
                    const InputDecoration(labelText: 'Medium'),
                keyboardType: TextInputType.number,
              ),

              TextField(
                controller: _largeController,
                decoration:
                    const InputDecoration(labelText: 'Large'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAll,
                  child: const Text('Guardar Cambios'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateExchangeRates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Actualizar Tasas Binance',
                    style: TextStyle(
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
