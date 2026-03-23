import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../shared/models/user.dart';
import '../auth/login_screen.dart';

import '../communications/screens/chat_screen.dart';
import '../communications/services/communications_service.dart';

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
  DateTime? _fromDate;
  DateTime? _toDate;
  int _unreadCount = 0;
  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count =
          await CommunicationsService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadCount = count;
      });
    } catch (_) {}
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

        _commissionRate =
            double.tryParse(
                    summary['commission_rate']?.toString() ??
                        '0') ??
                0;

        _orders = summary['orders'] ?? [];

          _totalEarned = 0;

          for (final o in _orders) {
            final total =
                double.tryParse(o['total']?.toString() ?? '0') ?? 0;

            _totalEarned += total * (_commissionRate / 100);
          }        

          print("TIPO DE ORDERS: ${_orders.runtimeType}");
          print("PRIMER ORDER: ${_orders.isNotEmpty ? _orders.first : "vacío"}");

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
    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.black,
      onPressed: () async {
        final user = AuthService().currentUser;
        if (user == null) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserId: 1, // ACA DEBERIA SER IDE ADMIN SIEMPRE
              currentUserId: user.id,
            ),
          ),
        );

        _loadUnreadCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.support_agent, color: Colors.white),

          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
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

Widget _summaryCard({
  required double sold,
  required double earned,
}) {
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
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryItem(
          "Vendido",
          "\$${sold.toStringAsFixed(0)}",
          Icons.shopping_cart,
        ),
        _summaryItem(
          "Comisión",
          "${_commissionRate.toStringAsFixed(0)}%",
          Icons.percent,
        ),
        _summaryItem(
          "Ganado",
          "\$${earned.toStringAsFixed(0)}",
          Icons.attach_money,
        ),
      ],
    ),
  );
}

Widget _summaryItem(
  String label,
  String value,
  IconData icon,
) {
  return Column(
    children: [
      Icon(icon, color: Colors.black54),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    ],
  );
}


Widget _orderCard(dynamic order) {
  final total =
      double.tryParse(order['total']?.toString() ?? '0') ?? 0;

  final commission =
      total * (_commissionRate / 100);

  final created =
      DateTime.tryParse(order['created_at'] ?? '');

  String date = '';
  if (created != null) {
    date =
        "${created.day}/${created.month}/${created.year}";
  }

  final status = order['status'];

  Color statusColor;
  String statusLabel;

  switch (status) {
    case 'pending':
      statusColor = Colors.orange;
      statusLabel = 'Pendiente';
      break;

    case 'requested':
      statusColor = Colors.blue;
      statusLabel = 'Solicitado';
      break;

    case 'approvedForPayment':
      statusColor = Colors.deepPurple;
      statusLabel = 'Listo para pago';
      break;

    case 'delivered':
      statusColor = Colors.green;
      statusLabel = 'Entregado';
      break;

    default:
      statusColor = Colors.grey;
      statusLabel = status;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Row(
              children: [

                Text(
                  "Pedido #${order['id']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(width: 8),

                if (order['client_name'] != null)
                  Expanded(
                    child: Text(
                      order['client_name'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

              ],
            ),

        if (date.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            date,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Venta",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "\$${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                const Text(
                  "Ganancia",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "\$${commission.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
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

  // 🔹 Filtrar por fecha si se selecciona
  final filteredOrders = _orders.where((o) {
    if (_fromDate == null && _toDate == null) return true;

    final created = DateTime.tryParse(o['created_at'] ?? '');
    if (created == null) return false;

    if (_fromDate != null && created.isBefore(_fromDate!)) {
      return false;
    }

    if (_toDate != null &&
        created.isAfter(_toDate!.add(const Duration(days: 1)))) {
      return false;
    }

    return true;
  }).toList();

    // 🔹 Calcular ventas y ganancias del rango seleccionado
    double soldInRange = 0;
    double earnedInRange = 0;

    for (final o in filteredOrders) {
      final total =
          double.tryParse(o['total']?.toString() ?? '0') ?? 0;

      soldInRange += total;

      earnedInRange += total * (_commissionRate / 100);
    }  

  // 🔹 Agrupar por estado
  final Map<String, List<dynamic>> grouped = {
    'pending': [],
    'requested': [],
    'approvedForPayment': [],
    'delivered': [],
  };

  for (final o in filteredOrders) {
    final status = o['status'];
    if (grouped.containsKey(status)) {
      grouped[status]!.add(o);
    }
  }

  final orderedStates = [
    'pending',
    'requested',
    'approvedForPayment',
    'delivered',
  ];

  String stateTitle(String state) {
    switch (state) {
      case 'pending':
        return 'Pendientes';
      case 'requested':
        return 'Solicitados';
      case 'approvedForPayment':
        return 'Listos para pago';
      case 'delivered':
        return 'Entregados';
      default:
        return state;
    }
  }

  return RefreshIndicator(
    onRefresh: _loadData,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _summaryCard(
          sold: soldInRange,
          earned: earnedInRange,
        ),

        const SizedBox(height: 20),

        // 🔹 FILTRO FECHAS
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() {
                      _fromDate = picked;
                    });
                  }
                },
                child: Text(
                  _fromDate == null
                      ? "Desde"
                      : "${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}",
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() {
                      _toDate = picked;
                    });
                  }
                },
                child: Text(
                  _toDate == null
                      ? "Hasta"
                      : "${_toDate!.day}/${_toDate!.month}/${_toDate!.year}",
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        const Text(
          'Pedidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        if (filteredOrders.isEmpty)
          const Text('No hay pedidos en este rango')
        else
          ...orderedStates.expand((state) {
            final orders = grouped[state]!;
            if (orders.isEmpty) return [];

            return [
              const SizedBox(height: 20),

              Text(
                stateTitle(state),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              ...orders.map(_orderCard),
            ];
          }),
      ],
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