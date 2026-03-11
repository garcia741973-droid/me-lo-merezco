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
  List<Order> _urgentOrders = [];
  List<Order> _inProcessOrders = [];
  List<Order> _paidOrders = [];
  List<Order> _deliveredOrders = [];
  List<Order> _rejectedOrders = [];

  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();

  String? _selectedStatus;

  int _offset = 0;
  final int _limit = 20; // aca se cambia limite para cargar mas
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

Future<void> _loadOrders({
  String? status,
  String? search,
}) async {
  try {
          final orders = await OrderService.fetchAdminOrdersFiltered(
            status: _selectedStatus,
            search: search,
            limit: _limit,
            offset: _offset,
          );

              if (orders.length < _limit) {
                _hasMore = false;
              } else {
                _hasMore = true;
              }

    setState(() {
      _urgentOrders = orders.where((o) =>
          o.status == OrderStatus.requested ||
          o.status == OrderStatus.paymentSent).toList();

      _inProcessOrders = orders.where((o) =>
          o.status == OrderStatus.approvedForPayment).toList();

      _paidOrders = orders.where((o) =>
          o.status == OrderStatus.paid).toList();

      _deliveredOrders = orders.where((o) =>
          o.status == OrderStatus.delivered).toList();

      _rejectedOrders = orders.where((o) =>
          o.status == OrderStatus.rejected).toList();

      _loading = false;
    });
  } catch (e) {
    debugPrint('Error loading admin dashboard: $e');
    setState(() {
      _loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null ||
        (user.role != UserRole.admin &&
        user.role != UserRole.operador)) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de pedidos'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'requested', child: Text('Requested')),
                    DropdownMenuItem(value: 'approvedForPayment', child: Text('Approved')),
                    DropdownMenuItem(value: 'paymentSent', child: Text('Payment Sent')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                      _offset = 0;     // 👈 RESET PAGINACIÓN
                      _loading = true;
                    });
                    _loadOrders();
                  },
                ),

                const SizedBox(height: 16),
                  
                  // 🔎 BUSCADOR PROFESIONAL
                  // 🔎 BUSCADOR CON BOTÓN REAL
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Buscar pedido por ID...',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              final value = _searchController.text.trim();
                              if (value.isEmpty) return;

                              FocusScope.of(context).unfocus();

                              setState(() {
                                _offset = 0;       // 👈 RESET PAGINACIÓN
                                _loading = true;
                              });

                              _loadOrders(search: value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),  
                  _buildSection("🔴 Tareas urgentes", _urgentOrders),
                  _buildSection("🟡 En proceso", _inProcessOrders),
                  _buildSection("🟢 Pagados", _paidOrders),
                  _buildSection("📦 Entregados", _deliveredOrders),
                  _buildSection("❌ Rechazados", _rejectedOrders),
                  if (_urgentOrders.isEmpty &&
                      _inProcessOrders.isEmpty &&
                      _paidOrders.isEmpty &&
                      _deliveredOrders.isEmpty &&
                      _rejectedOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('No hay pedidos'),
                      ),
                    ),
                    if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _offset += _limit;
                            _loading = true;
                          });
                          _loadOrders();
                        },
                        child: const Text('Cargar más'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Order> orders) {
    if (orders.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...orders.map((order) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminOrderDetailScreen(orderId: order.id),
                  ),
                );
                setState(() {
                  _offset = 0;
                });
                _loadOrders();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pedido #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(order.status)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status.name,
                            style: TextStyle(
                              color: _statusColor(order.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: Bs ${order.total.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.requested:
        return Colors.red;
      case OrderStatus.paymentSent:
        return Colors.orange;
      case OrderStatus.approvedForPayment:
        return Colors.amber;
      case OrderStatus.paid:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.blue;
      case OrderStatus.rejected:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

}