import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';
import '../auth/auth_gate.dart';
import '../auth/change_password_screen.dart';

import 'client_orders_screen.dart';
import 'client_offers_screen.dart';
import '../quote/shein_webview_screen.dart';// 🔥 IMPORTANTE

/// ===============================
/// MODELO DE RESULTADO (COTIZACIÓN)
/// ===============================
class QuoteResult {
  final String id;
  final String platform;
  final String code;
  final String name;
  final double basePrice;

  QuoteResult({
    required this.id,
    required this.platform,
    required this.code,
    required this.name,
    required this.basePrice,
  });

  double get importPercent => 0.45;
  double get importCost => basePrice * importPercent;
  double get total => basePrice + importCost;
}

/// ===============================
/// HOME CLIENTE
/// ===============================
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final codeCtrl = TextEditingController();
  String platform = 'Shein';

  final List<QuoteResult> quotes = [];

  int _bottomIndex = 0;

  // ===============================
  // VALIDACIONES URL
  // ===============================
  bool _isValidSheinUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('shein.com');
    } catch (_) {
      return false;
    }
  }

  bool _isValidAmazonUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('amazon.');
    } catch (_) {
      return false;
    }
  }

  bool _isValidAliExpressUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('aliexpress.com');
    } catch (_) {
      return false;
    }
  }

  bool _isValidTemuUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('temu.com');
    } catch (_) {
      return false;
    }
  }

  // ===============================
  // COTIZAR (AHORA WEBVIEW)
  // ===============================
  Future<void> _cotizar() async {
    final input = codeCtrl.text.trim();
    if (input.isEmpty) return;

    if (platform != 'Shein') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plataforma aún no implementada'),
        ),
      );
      return;
    }

    if (!_isValidSheinUrl(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL Shein inválida')),
      );
      return;
    }

    // 🔥 ABRIR WEBVIEW
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SheinWebViewScreen(productUrl: input),
      ),
    );

if (result == null) return;

if (result['error'] != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['error'])),
  );
  return;
}

if (result['price'] == null || result['name'] == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No se pudo obtener información del producto'),
    ),
  );
  return;
}

final double basePrice =
    (result['price'] as num).toDouble();

final String name = result['name'];


    setState(() {
      quotes
        ..clear()
        ..add(
          QuoteResult(
            id: DateTime.now()
                .microsecondsSinceEpoch
                .toString(),
            platform: 'Shein',
            code: input,
            name: name,
            basePrice: basePrice,
          ),
        );
      codeCtrl.clear();
    });
  }

  // ===============================
  // AGREGAR AL CARRITO (NO TOCADO)
  // ===============================
  Future<void> _agregarAlCarrito(QuoteResult quote) async {
    final token = await AuthService().getToken();

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario no autenticado'),
        ),
      );
      return;
    }

    final res = await http.post(
      Uri.parse(
        'https://me-lo-merezco-backend.onrender.com/orders/add-quote',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_name': quote.name,
        'product_url': quote.code,
        'base_price': quote.basePrice,
      }),
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregado al carrito'),
        ),
      );

      setState(() {
        quotes.clear();
        _bottomIndex = 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error al agregar (${res.statusCode})'),
        ),
      );
    }
  }

  // ===============================
  // LOGOUT
  // ===============================
  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  // ===============================
  // VISTA COTIZAR
  // ===============================
  Widget _cotizarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: platform,
            items: const [
              DropdownMenuItem(value: 'Shein', child: Text('Shein')),
              DropdownMenuItem(value: 'Amazon', child: Text('Amazon')),
              DropdownMenuItem(value: 'Temu', child: Text('Temu')),
              DropdownMenuItem(value: 'AliExpress', child: Text('AliExpress')),
            ],
            onChanged: (v) => setState(() => platform = v!),
            decoration: const InputDecoration(labelText: 'Plataforma'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeCtrl,
            decoration:
                const InputDecoration(labelText: 'URL del producto'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _cotizar,
            child: const Text('Cotizar'),
          ),
          const SizedBox(height: 16),
          if (quotes.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quotes.first.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                        'Precio base: \$${quotes.first.basePrice.toStringAsFixed(2)}'),
                    Text(
                        'Costo importación: \$${quotes.first.importCost.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    Text(
                      'Total final: \$${quotes.first.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _agregarAlCarrito(quotes.first),
                      child: const Text('Agregar al carrito'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===============================
  // BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me lo merezco'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ChangePasswordScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _bottomIndex == 0
            ? _cotizarView()
            : _bottomIndex == 1
                ? const ClientOrdersScreen()
                : const ClientOffersScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          if (!mounted) return;
          setState(() => _bottomIndex = i);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calculate), label: 'Cotizar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Carrito'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: 'Ofertas'),
        ],
      ),
    );
  }
}
