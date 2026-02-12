import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';
import '../../shared/models/order.dart';

import '../payment/qr_payment_screen.dart';
import 'client_order_detail_screen.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  late Future<List<Order>> _ordersFuture;

  // cache de items por pedido
  final Map<int, List<dynamic>> _itemsCache = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = OrderService.fetchClientOrders();
  }

  Future<void> _preloadCartItems(List<Order> cartOrders) async {
    for (final order in cartOrders) {
      if (!_itemsCache.containsKey(order.id)) {
        final items = await OrderService.fetchOrderItems(order.id);
        if (!mounted) return;
        _itemsCache[order.id] = items;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _removeItem(int itemId) async {
    try {
      await OrderService.deleteOrderItem(itemId);
      _itemsCache.clear();
      setState(_loadOrders);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el producto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Error al cargar pedidos'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(_loadOrders),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        final cartOrders =
            orders.where((o) => o.status == OrderStatus.pending).toList();

        final sentOrders =
            orders.where((o) => o.status != OrderStatus.pending).toList();

        // 🔑 CARGA CONTROLADA DE ITEMS
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cartOrders.isNotEmpty) {
            _preloadCartItems(cartOrders);
          }
        });

        return RefreshIndicator(
          onRefresh: () async {
            _itemsCache.clear();
            setState(_loadOrders);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // =====================
              // 🛒 CARRITO
              // =====================
              if (cartOrders.isNotEmpty) ...[
                const Text(
                  '🛒 Mi carrito',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Estos productos aún no son un pedido.\n'
                  'Solicita validación para que el admin revise la cotización.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...cartOrders.map((order) {
                  final items = _itemsCache[order.id] ?? [];
                  return _cartOrderCard(order, items);
                }),
                const SizedBox(height: 24),
              ],

              // =====================
              // 📦 PEDIDOS
              // =====================
              if (sentOrders.isNotEmpty) ...[
                const Text(
                  '📦 Mis pedidos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...sentOrders.map(
                  (order) => _sentOrderCard(context, order),
                ),
              ],

              if (cartOrders.isEmpty && sentOrders.isEmpty)
                const Center(child: Text('No tienes pedidos todavía')),
            ],
          ),
        );
      },
    );
  }

  // ================= UI HELPERS =================

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------- CARRITO ----------

  Widget _cartOrderCard(Order order, List<dynamic> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Pedido #', order.id.toString()),
            _row('Estado', 'En carrito'),
            _row('Total', '\$${order.total.toStringAsFixed(2)}'),
            const Divider(height: 24),

            if (items.isEmpty)
              const Text('Cargando productos...')
            else
              Column(
  children: items.map((item) {
    final quantity = item['quantity'] ?? 1;
    final price = double.parse(item['price'].toString());
    final totalItem = price * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? 'Producto',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: $quantity',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                if (item['source_type'] == 'offer')
                  const Text(
                    'Tipo: Oferta',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                if (item['source_type'] == 'quote')
                  const Text(
                    'Tipo: Cotización',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalItem.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)} c/u',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeItem(item['id']),
          ),
        ],
      ),
    );
  }).toList(),
),


            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: items.isEmpty
                    ? null
                    : () async {
                        await OrderService.requestOrderValidation(order.id);
                        _itemsCache.clear();
                        setState(_loadOrders);
                      },
                child: const Text('Enviar pedido para validación'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- PEDIDOS ----------

  Widget _sentOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Pedido #', order.id.toString()),
            _row('Estado', _formatStatus(order.status)),
            _row('Total', '\$${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            _actionForStatus(context, order),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ClientOrderDetailScreen(orderId: order.id),
                    ),
                  );
                  setState(_loadOrders);
                },
                child: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionForStatus(BuildContext context, Order order) {
    switch (order.status) {
      case OrderStatus.approvedForPayment:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrPaymentScreen(
                    orderId: order.id.toString(),
                    amount: order.total,
                  ),
                ),
              );
              setState(_loadOrders);
            },
            child: const Text('Pagar por QR'),
          ),
        );

      case OrderStatus.paymentSent:
        return const Text(
          'Esperando confirmación del pago',
          style: TextStyle(color: Colors.orange),
        );

      case OrderStatus.paid:
        return const Text(
          'Preparando entrega',
          style: TextStyle(color: Colors.green),
        );

      case OrderStatus.delivered:
        return const Text(
          'Pedido entregado',
          style: TextStyle(color: Colors.blue),
        );

      default:
        return const Text(
          'En proceso',
          style: TextStyle(color: Colors.grey),
        );
    }
  }

  String _formatStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.requested:
        return 'Solicitud enviada';
      case OrderStatus.approvedForPayment:
        return 'Aprobado para pago';
      case OrderStatus.paymentSent:
        return 'Pago enviado';
      case OrderStatus.paid:
        return 'Preparando entrega';
      case OrderStatus.delivered:
        return 'Entregado';
      default:
        return status.name;
    }
  }
}
