import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../shared/models/user.dart';
import '../auth/login_screen.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() =>
      _SellerOrdersScreenState();
}

class _SellerOrdersScreenState
    extends State<SellerOrdersScreen> {
  bool _loading = true;
  String? _error;

  double _totalSold = 0;
  double _totalEarned = 0;
  double _commissionRate = 0;

  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summary =
          await OrderService.fetchSellerSummary();

      if (!mounted) return;

      setState(() {
        _totalSold =
            double.tryParse(
                    summary['total_paid']?.toString() ?? '0') ??
                0;

        _totalEarned =
            double.tryParse(
                    summary['total_earned']?.toString() ?? '0') ??
                0;

        _commissionRate =
            double.tryParse(
                    summary['commission_rate']?.toString() ??
                        '0') ??
                0;

        _orders = summary['orders'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null || user.role != UserRole.seller) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Stack(
        children: [

          // 🌿 Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/logos/fondoGeneral.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // 🔝 HEADER CUSTOM
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mis ventas",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadData,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'logout') {
                                AuthService().logout();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'logout',
                                child: Text('Cerrar sesión'),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _summaryCard(),
          const SizedBox(height: 30),
          const Text(
            'Pedidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          if (_orders.isEmpty)
            const Text('No tienes pedidos asignados')
          else
            ..._orders.map(_orderCard).toList(),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _row(
            'Total vendido (pagado)',
            '\$${_totalSold.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _row(
            'Comisión',
            '${_commissionRate.toStringAsFixed(2)}%',
          ),
          const Divider(height: 28),
          _row(
            'Total ganado',
            '\$${_totalEarned.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _orderCard(dynamic order) {
    final total =
        double.tryParse(order['total']?.toString() ?? '0') ??
            0;

    final commission =
        total * (_commissionRate / 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        title: Text(
          'Pedido #${order['id']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total: \$${total.toStringAsFixed(2)}\n'
          'Estado: ${order['status']}',
        ),
        trailing: Text(
          '\$${commission.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}