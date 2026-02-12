import 'package:flutter/material.dart';

import '../../shared/models/quote.dart';
import 'quote_result_screen.dart';

import '../seller/seller_dashboard_screen.dart';
import '../client/client_orders_screen.dart';
import '../admin/admin_orders_screen.dart';
import '../auth/login_screen.dart';

import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final TextEditingController _productController = TextEditingController();
  bool _isLoading = false;

  void _quoteProduct() async {
    if (_productController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // 🔹 Simulación backend
    await Future.delayed(const Duration(seconds: 2));

    final quote = Quote(
      productName: _productController.text,
      basePrice: 120.00,
      shipping: 35.00,
      margin: 25.00,
    );

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteResultScreen(quote: quote),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizar producto'),
        centerTitle: true,
        actions: [
          // 🛒 Carrito
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientOrdersScreen(),
                ),
              );
            },
          ),

          // 👤 Menú usuario
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'client_orders':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientOrdersScreen(),
                    ),
                  );
                  break;

                case 'seller_panel':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SellerDashboardScreen(),
                    ),
                  );
                  break;

                case 'admin_orders':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminOrdersScreen(),
                    ),
                  );
                  break;

                case 'logout':
                  AuthService().logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                // ℹ️ Info usuario
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.role == UserRole.seller
                            ? 'Vendedor / Administrador'
                            : 'Cliente',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                // 👤 Cliente
                if (user.role == UserRole.client)
                  const PopupMenuItem(
                    value: 'client_orders',
                    child: Text('Mis pedidos'),
                  ),

                // 🧑‍💼 Vendedor
                if (user.role == UserRole.seller)
                  const PopupMenuItem(
                    value: 'seller_panel',
                    child: Text('Panel de vendedor'),
                  ),

                // 🛂 Admin (mismo rol seller por ahora)
                if (user.role == UserRole.seller)
                  const PopupMenuItem(
                    value: 'admin_orders',
                    child: Text('Solicitudes de pago'),
                  ),

                const PopupMenuDivider(),

                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Cerrar sesión'),
                ),
              ];
            },
          ),
        ],
      ),

      // ---------------- BODY ----------------

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Pega el código o link del producto',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _productController,
              decoration: const InputDecoration(
                hintText: 'Ej: Código Shein / Link EMU',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _quoteProduct,
                      child: const Text('Cotizar'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
