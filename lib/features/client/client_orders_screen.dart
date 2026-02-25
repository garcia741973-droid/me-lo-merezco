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

  final Map<int, List<dynamic>> _itemsCache = {};
  final Map<int, bool> _expandedItems = {};
  final Set<int> _processingItems = {};

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
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/logos/fondoGeneral.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(10, 10, 30, 0.85),
            Color.fromRGBO(20, 0, 40, 0.75),
          ],
        ),
      ),
      child: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar pedidos',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          final cartOrders =
              orders.where((o) => o.status == OrderStatus.pending).toList();

          final sentOrders =
              orders.where((o) => o.status != OrderStatus.pending).toList();

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
                if (cartOrders.isNotEmpty) ...[
                  const Text(
                    '🛒 Mi carrito',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...cartOrders.map((order) {
                    final items = _itemsCache[order.id] ?? [];
                    return _cartOrderCard(order, items);
                  }),
                  const SizedBox(height: 32),
                ],
                if (sentOrders.isNotEmpty) ...[
                  const Text(
                    '📦 Mis pedidos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sentOrders.map(
                    (order) => _sentOrderCard(context, order),
                  ),
                ],
                if (cartOrders.isEmpty && sentOrders.isEmpty)
                  const Center(
                    child: Text(
                      'No tienes pedidos todavía',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}


 Widget _cartOrderCard(Order order, List<dynamic> items) {
  return Card(
    color: Colors.white.withOpacity(0.9),
    elevation: 8,
    shadowColor: Colors.black.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    margin: const EdgeInsets.only(bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Pedido #', order.id.toString()),
            _row('Estado', 'En carrito'),
            const SizedBox(height: 6),
            Text(
              'TOTAL Bs ${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const Divider(height: 28),

            if (!_itemsCache.containsKey(order.id))
              const Text('Cargando productos...')
            else if (items.isEmpty)
              const Text('No hay productos en este pedido')
            else
              Column(
                children: items.map((item) {
                  final quantity = item['quantity'] ?? 1;
                  final price =
                      double.parse(item['price'].toString());
                  final totalItem = price * quantity;

                  final itemId = item['id'];
                  final isExpanded =
                      _expandedItems[itemId] ?? false;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedItems[itemId] =
                                    !isExpanded;
                              });
                            },
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'] ??
                                      'Producto',
                                  maxLines:
                                      isExpanded ? null : 2,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (!isExpanded)
                                  const Text(
                                    'Ver más',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
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
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bs ${totalItem.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bs ${price.toStringAsFixed(2)} c/u',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        // ---------- START: reemplazo por-item ----------
if (order.status == OrderStatus.pending)
  SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botón enviar por item (solo si el item está pending)
        if (item['status'] == 'pending')
          SizedBox(
            height: 36,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processingItems.contains(itemId)
    ? null
    : () async {
        try {
          setState(() => _processingItems.add(itemId));

          final oldTotal = order.total;

          // 1️⃣ Recalcular cotizaciones
          final newTotal =
              await OrderService.recalculateQuotes(order.id);

          if (!mounted) return;

          // 2️⃣ Si cambió el total → mostrar diálogo
          if ((newTotal - oldTotal).abs() > 0.01) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cambio en cotización'),
                content: Text(
                  'El tipo de cambio ha variado.\n\n'
                  'Total anterior: Bs ${oldTotal.toStringAsFixed(2)}\n'
                  'Nuevo total: Bs ${newTotal.toStringAsFixed(2)}\n\n'
                  '¿Deseas continuar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, true),
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            );

            if (confirm != true) {
              return;
            }
          }

          // 3️⃣ Enviar item a validación
          await OrderService.requestItemValidation(itemId);

          _itemsCache.clear();
          setState(_loadOrders);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ítem enviado para validación'),
            ),
          );
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error enviando ítem: $e'),
            ),
          );
        } finally {
          if (mounted) {
            setState(() =>
                _processingItems.remove(itemId));
          }
        }
      },

              child: _processingItems.contains(itemId)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar',
                      style: TextStyle(fontSize: 12),
                    ),
            ),
          ),

        const SizedBox(height: 6),

        // Botón eliminar (solo si sigue pending)
        if (item['status'] == 'pending')
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeItem(itemId),
          )
        else
          Text(
            _formatItemStatus(item['status']),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _itemStatusColor(item['status']),
              fontSize: 12,
            ),
          ),
      ],
    ),
  )
// Si el pedido no está en pending (raro porque estamos en carrito) no mostramos controles
else
  const SizedBox.shrink(),
// ---------- END: reemplazo por-item ----------

                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 18),


          ],
        ),
      ),
    ),
  );
}


Widget _sentOrderCard(BuildContext context, Order order) {
  return Card(
    color: Colors.white.withOpacity(0.95),
    elevation: 8,
    shadowColor: Colors.black.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    margin: const EdgeInsets.only(bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Pedido #', order.id.toString()),
            _row('Estado', _formatStatus(order.status)),
            const SizedBox(height: 6),
            Text(
              'TOTAL Bs ${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 14),
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
    ),
  );
}


  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
  String _formatItemStatus(String status) {
  switch (status) {
    case 'pending':
      return 'Pendiente';
    case 'requested':
      return 'En validación';
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
    case 'requested':
      return Colors.orange;
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

}
