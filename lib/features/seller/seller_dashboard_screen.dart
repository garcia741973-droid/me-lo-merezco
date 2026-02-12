import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import 'seller_orders_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de vendedor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Info del vendedor
            Text(
              'Hola ${user.name}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rol: Vendedor',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              'Comisión: ${(user.commissionRate! * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const Divider(height: 32),

            // 📊 Resumen
            _infoCard(
              title: 'Clientes asociados',
              value: AuthService().getAssociatedClientsCount().toString(),
            ),
            _infoCard(
              title: 'Comisión acumulada',
              value: '\$180.00', // fake por ahora
            ),

            const SizedBox(height: 24),

            // 📦 Acción principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SellerOrdersScreen(),
                    ),
                  );
                },
                child: const Text('Ver pedidos'),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
