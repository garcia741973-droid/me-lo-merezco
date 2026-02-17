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
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final allOrders = await OrderService.fetchClientOrders();

      // 🔎 Admin ve solo pedidos solicitados
      final requestedOrders = allOrders
          .where((o) => o.status == OrderStatus.requested)
          .toList();

      setState(() {
        _orders = requestedOrders;
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
        title: const Text('Pedidos pendientes'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Text('No hay pedidos pendientes'),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('Pedido #${order.id}'),
                          subtitle: Text(
                            'Total actual: \$${order.total.toStringAsFixed(2)}',
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
                    },
                  ),
                ),
    );
  }
}
