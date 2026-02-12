import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';
import '../auth/login_screen.dart';
import '../client/client_order_detail_screen.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    // 🔐 Protección: si no hay admin, volver a login
    if (user == null || user.role != UserRole.admin) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos (Admin)'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().logout();

              // 🔥 ESTO es lo que faltaba
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Abrir pedido #1'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const ClientOrderDetailScreen(orderId: 1),
              ),
            );
          },
        ),
      ),
    );
  }
}
