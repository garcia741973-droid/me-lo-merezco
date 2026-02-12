import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';
import '../../shared/models/order.dart';

class ClientOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const ClientOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<ClientOrderDetailScreen> createState() =>
      _ClientOrderDetailScreenState();
}

class _ClientOrderDetailScreenState
    extends State<ClientOrderDetailScreen> {
  Order? _order;
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final order =
          await OrderService.fetchOrder(widget.orderId);
      final items =
          await OrderService.fetchOrderItems(widget.orderId);

      setState(() {
        _order = order;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading order: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return const Scaffold(
        body: Center(child: Text('No se pudo cargar el pedido')),
      );
    }

    final user = AuthService().currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final isClient = user?.role == UserRole.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del pedido'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Pedido ID', _order!.id.toString()),
            const Divider(),

            _row(
              'Costo de importación',
              '\$${_order!.total.toStringAsFixed(2)}',
            ),

            _row(
              'Estado',
              _formatStatus(_order!.status),
            ),

            const SizedBox(height: 24),

            const Text(
              'Ítems del pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text('No hay ítems en este pedido'),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];

                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item['product_name']),
                            subtitle: Text(
                              'Precio: \$${item['price']}',
                            ),
                            trailing: item['status'] == 'pending' &&
                                    isAdmin
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Aprobar',
                                        onPressed: () async {
                                          await OrderService
                                              .approveItem(item['id']);
                                          await _loadData();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Rechazar',
                                        onPressed: () async {
                                          await OrderService
                                              .rejectItem(item['id']);
                                          await _loadData();
                                        },
                                      ),
                                    ],
                                  )
                                : Text(
                                    _formatItemStatus(item['status']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _itemStatusColor(
                                        item['status'],
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            _statusMessage(_order!.status),

            const SizedBox(height: 16),

            if (isClient)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Volver a mis pedidos'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _statusMessage(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const Text(
        'Este pedido está en el carrito',
        style: TextStyle(color: Colors.grey),
      );

    case OrderStatus.requested:
      return const Text(
        'Tu solicitud está siendo validada.',
        style: TextStyle(color: Colors.orange),
      );

    case OrderStatus.approved:
      return const Text(
        'Pedido aprobado.',
        style: TextStyle(color: Colors.green),
      );

    case OrderStatus.approvedForPayment:
      return const Text(
        'Pedido aprobado, listo para pagar.',
        style: TextStyle(color: Colors.green),
      );

    case OrderStatus.paymentSent:
      return const Text(
        'Pago enviado, esperando confirmación.',
        style: TextStyle(color: Colors.blue),
      );

    case OrderStatus.paid:
      return const Text(
        'Pago confirmado, preparando entrega.',
        style: TextStyle(color: Colors.teal),
      );

    case OrderStatus.delivered:
      return const Text(
        'Pedido entregado.',
        style: TextStyle(color: Colors.purple),
      );
  }
}

  String _formatStatus(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'En carrito';
    case OrderStatus.requested:
      return 'Solicitud enviada';
    case OrderStatus.approved:
      return 'Aprobado';
    case OrderStatus.approvedForPayment:
      return 'Aprobado para pago';
    case OrderStatus.paymentSent:
      return 'Pago enviado';
    case OrderStatus.paid:
      return 'Pagado';
    case OrderStatus.delivered:
      return 'Entregado';
  }
}


  String _formatItemStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }

  Color _itemStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.grey;
    case OrderStatus.requested:
      return Colors.grey;
    case OrderStatus.approved:
      return Colors.green;
    case OrderStatus.approvedForPayment:
      return Colors.blue;
    case OrderStatus.paymentSent:
      return Colors.orange;
    case OrderStatus.paid:
      return Colors.green;
    case OrderStatus.delivered:
      return Colors.teal;
  }
}
}
