import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/models/order.dart';
import '../../shared/models/user.dart';

import '../auth/login_screen.dart';

class AdminConfirmPaymentsScreen extends StatefulWidget {
  const AdminConfirmPaymentsScreen({super.key});

  @override
  State<AdminConfirmPaymentsScreen> createState() =>
      _AdminConfirmPaymentsScreenState();
}

class _AdminConfirmPaymentsScreenState
    extends State<AdminConfirmPaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    // 🔐 Protección por rol
    if (user == null || user.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso denegado'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('No tienes permisos para confirmar pagos'),
        ),
      );
    }

    final orders = OrderService.getOrdersByStatus(OrderStatus.paymentSent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar pagos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => setState(() {}),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                AuthService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),
            ],
          ),
        ],
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text('No hay pagos pendientes de confirmación'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido ${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Cliente: ${order.clientName}'),
                        const SizedBox(height: 4),
                        Text(
                          'Monto: \$${order.total.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              OrderService.updateOrderStatus(
                                order.id,
                                OrderStatus.paid,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pago confirmado'),
                                ),
                              );

                              setState(() {});
                            },
                            child: const Text('Confirmar pago'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
