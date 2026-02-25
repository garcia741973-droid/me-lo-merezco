import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';
import '../../shared/models/order.dart';
import '../auth/login_screen.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _requestedOrders = [];
  List<Order> _paymentPendingOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final allOrders = await OrderService.fetchClientOrders();

      final requestedOrders = allOrders
          .where((o) => o.status == OrderStatus.requested)
          .toList();

      final paymentPendingOrders = allOrders
          .where((o) => o.status == OrderStatus.paymentSent)
          .toList();

      setState(() {
        _requestedOrders = requestedOrders;
        _paymentPendingOrders = paymentPendingOrders;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin orders: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null || user.role != UserRole.admin) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de pedidos'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ============================
                  // 📥 PENDIENTES DE VALIDACIÓN
                  // ============================
                  if (_requestedOrders.isNotEmpty) ...[
                    const Text(
                      '📥 Pendientes de validación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._requestedOrders.map((order) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('Pedido #${order.id}'),
                          subtitle: Text(
                            'Total: \$${order.total.toStringAsFixed(2)}',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminOrderDetailScreen(
                                  orderId: order.id,
                                ),
                              ),
                            );
                            _loadOrders();
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // ============================
                  // 💳 PAGOS PENDIENTES
                  // ============================
                  if (_paymentPendingOrders.isNotEmpty) ...[
                    const Text(
                      '💳 Pagos pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._paymentPendingOrders.map((order) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('Pedido #${order.id}'),
                          subtitle: Text(
                            'Total: \$${order.total.toStringAsFixed(2)}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await OrderService.confirmPayment(order.id);
                              _loadOrders();
                            },
                            child: const Text('Confirmar pago'),
                          ),
                        ),
                      );
                    }),
                  ],

                  // ============================
                  // SIN PEDIDOS
                  // ============================
                  if (_requestedOrders.isEmpty &&
                      _paymentPendingOrders.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text('No hay pedidos pendientes'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
