import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';
import '../../shared/models/order.dart';

import 'client_order_detail_screen.dart';

import '../../core/services/auth_service.dart';

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

  DateTime? _fromDate;
  DateTime? _toDate;
  OrderStatus? _statusFilter;

//  @override
//  void didChangeDependencies() {
//    super.didChangeDependencies();
//    _loadOrders();
//  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

    void _loadOrders() {
      if (AuthService().currentUser == null) {
        _ordersFuture = Future.value([]);
      } else {
        _ordersFuture = OrderService.fetchClientOrders();
      }

      if (mounted) {
        setState(() {});
      }
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

    _loadOrders();

//    setState(() {});
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

            // ✅ FILTRO POR FECHAS (sin romper: si no hay fecha en Order, no filtra)
            final filteredOrders = orders.where((o) {

              // filtro por fecha
              if (_fromDate != null && o.createdAt != null) {
                if (o.createdAt!.isBefore(_fromDate!)) {
                  return false;
                }
              }

              if (_toDate != null && o.createdAt != null) {
                if (o.createdAt!.isAfter(_toDate!.add(const Duration(days: 1)))) {
                  return false;
                }
              }

              // filtro por estado
              if (_statusFilter != null && o.status != _statusFilter) {
                return false;
              }

              return true;

            }).toList();

            final cartOrders = filteredOrders
                .where((o) => o.status == OrderStatus.pending)
                .toList();

            final sentOrders = filteredOrders
                .where((o) => o.status != OrderStatus.pending)
                .toList();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (cartOrders.isNotEmpty) {
                _preloadCartItems(cartOrders);
              }
            });

            return RefreshIndicator(
              onRefresh: () async {
                _itemsCache.clear();
                _loadOrders();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                _buildStatusFilter(orders),
                const SizedBox(height: 16),

                // ✅ SELECTOR FECHAS (igual que vendedor)
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
                  const SizedBox(height: 20),

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

                    // ✅ AGRUPADO POR ESTADO
                    ..._groupOrdersByStatus(context, sentOrders),
                  ],

                  if (AuthService().currentUser == null)
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Inicia sesión para ver tu carrito y pedidos',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text('Iniciar sesión'),
                          ),
                        ],
                      ),
                    )
                  else if (cartOrders.isEmpty && sentOrders.isEmpty)
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

  // =========================
  // ✅ Agrupar pedidos por estado (fuera del ListView)
  // =========================
  List<Widget> _groupOrdersByStatus(
    BuildContext context,
    List<Order> orders,
  ) {
    final Map<OrderStatus, List<Order>> grouped = {};

    for (final order in orders) {
      grouped.putIfAbsent(order.status, () => []);
      grouped[order.status]!.add(order);
    }

    // orden estable (como vendedor)
    final orderStates = [
      OrderStatus.requested,
      OrderStatus.approvedForPayment,
      OrderStatus.paymentSent,
      OrderStatus.paid,
      OrderStatus.delivered,
      OrderStatus.rejected,
    ];

    final widgets = <Widget>[];

    for (final status in orderStates) {
      final list = grouped[status] ?? [];
      if (list.isEmpty) continue;

      widgets.add(const SizedBox(height: 18));
      widgets.add(
        Text(
          _formatStatus(status),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(list.map((o) => _sentOrderCard(context, o)));
    }

    return widgets;
  }

  // =========================
  // ✅ helper fecha (seguro)
  // =========================
  DateTime? _orderDate(Order order) {
    // Si tu Order tiene createdAt, esto compila:
    // return order.createdAt;
    //
    // Para no romper si NO existe, dejamos null.
    // Si quieres, me confirmas tu model y lo ajusto 100%.
    try {
      final dynamic anyOrder = order;
      final d = anyOrder.createdAt;
      if (d is DateTime) return d;
      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================
  // CARDS
  // =========================

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
                    final price = double.parse(item['price'].toString());
                    final totalItem = price * quantity;

                    final itemId = item['id'];
                    final isExpanded = _expandedItems[itemId] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // -------- NOMBRE Y CANTIDAD
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedItems[itemId] = !isExpanded;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'] ?? 'Producto',
                                  maxLines: isExpanded ? null : 2,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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

                          const SizedBox(height: 8),

                          // -------- PRECIOS + CONTROLES
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // PRECIOS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bs ${totalItem.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
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
                              ),

                              // ---- controles por item (SIN CAMBIOS)
                              if (order.status == OrderStatus.pending)
                                SizedBox(
                                  width: 90,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (item['status'] == 'pending')
                                        SizedBox(
                                          height: 36,
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _processingItems.contains(itemId)
                                                ? null
                                                : () async {
                                                    try {
                                                      setState(() =>
                                                          _processingItems.add(itemId));

                                                      final oldTotal = order.total;

                                                      final newTotal =
                                                          await OrderService.recalculateQuotes(
                                                              order.id);

                                                      if (!mounted) return;

                                                      if ((newTotal - oldTotal).abs() > 0.01) {
                                                        final confirm =
                                                            await showDialog<bool>(
                                                          context: context,
                                                          builder: (_) => AlertDialog(
                                                            title: const Text(
                                                                'Cambio en cotización'),
                                                            content: Text(
                                                              'El tipo de cambio ha variado.\n\n'
                                                              'Total anterior: Bs ${oldTotal.toStringAsFixed(2)}\n'
                                                              'Nuevo total: Bs ${newTotal.toStringAsFixed(2)}\n\n'
                                                              '¿Deseas continuar?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context, false),
                                                                child: const Text(
                                                                    'Cancelar'),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context, true),
                                                                child: const Text(
                                                                    'Continuar'),
                                                              ),
                                                            ],
                                                          ),
                                                        );

                                                        if (confirm != true) {
                                                          return;
                                                        }
                                                      }

                                                      await OrderService
                                                          .requestItemValidation(itemId);

                                                      _itemsCache.clear();
                                                      _loadOrders();

                                                      if (!mounted) return;

                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Ítem enviado para validación'),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      if (!mounted) return;

                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Error enviando ítem: $e'),
                                                        ),
                                                      );
                                                    } finally {
                                                      if (mounted) {
                                                        setState(() =>
                                                            _processingItems.remove(
                                                                itemId));
                                                      }
                                                    }
                                                  },
                                            child: _processingItems.contains(itemId)
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
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
                                      if (item['status'] == 'pending')
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _removeItem(itemId),
                                        )
                                      else
                                        Text(
                                          _formatItemStatus(item['status']),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _itemStatusColor(
                                                item['status']),
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
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
  final items = _itemsCache[order.id] ?? [];

  if (!_itemsCache.containsKey(order.id)) {
    OrderService.fetchOrderItems(order.id).then((value) {
      if (!mounted) return;
      setState(() {
        _itemsCache[order.id] = value;
      });
    });
  }

  return Card(
    color: Colors.white.withOpacity(0.95),
    elevation: 8,
    shadowColor: Colors.black.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    margin: const EdgeInsets.only(bottom: 20),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Pedido
          Text(
            "Pedido #${order.id}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 4),

          /// Fecha
          Text(
            order.createdAt == null
            ? ''
            : "${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 8),

          /// Estado
          Text(
            _formatStatus(order.status),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const Divider(height: 20),

          /// PRODUCTOS
          if (!_itemsCache.containsKey(order.id))
            const Text("Cargando productos...")

          else if (items.isEmpty)
            const Text("Sin productos")

          else
            Column(
              children: items.map((item) {

                final quantity = item['quantity'] ?? 1;
                final price = double.parse(item['price'].toString());
                final total = price * quantity;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [

                      /// nombre producto
                      Expanded(
                        child: Text(
                          item['product_name'] ?? 'Producto',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      /// precio
                      Text(
                        "Bs ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 14),

          /// TOTAL
          Text(
            'TOTAL Bs ${order.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 12),

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

              _loadOrders(); // 🔥 CLAVE
              },
              child: const Text('Ver detalle'),
            ),
          ),

          if (order.status == OrderStatus.delivered ||
              order.status == OrderStatus.rejected)
            TextButton(
              onPressed: () async {

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Eliminar pedido'),
                    content: const Text(
                      'Este pedido se eliminará de tu historial visible.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                try {

                  await OrderService.archiveOrder(order.id);

                  if (!mounted) return;

                  _loadOrders();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido eliminado del historial'),
                    ),
                  );

                } catch (e) {

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error eliminando pedido: $e'),
                    ),
                  );
                }

              },
              child: const Text(
                'Eliminar de mi historial',
                style: TextStyle(color: Colors.red),
              ),
            ),

        ],
      ),
    ),
  );
}

  // =========================
  // Helpers
  // =========================

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  String _formatStatus(OrderStatus status) {
    switch (status) {

      case OrderStatus.requested:
        return '🟡 En validación';

      case OrderStatus.approvedForPayment:
        return '🟢 Aprobado para pago';

      case OrderStatus.paymentSent:
        return '🔵 Pago enviado';

      case OrderStatus.paid:
        return '🟣 Pagado';

      case OrderStatus.delivered:
        return '⚫ Entregado';

      case OrderStatus.rejected:
        return '🔴 Rechazado';

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

  Widget _buildStatusFilter(List<Order> orders) {

    int count(OrderStatus? status) {
      if (status == null) return orders.length;
      return orders.where((o) => o.status == status).length;
    }

    final statuses = [
      null,
      OrderStatus.requested,
      OrderStatus.approvedForPayment,
      OrderStatus.paymentSent,
      OrderStatus.paid,
      OrderStatus.delivered,
    ];

    String label(OrderStatus? s) {
      if (s == null) return "Todos (${count(null)})";

      switch (s) {
        case OrderStatus.requested:
          return "Validación (${count(s)})";
        case OrderStatus.approvedForPayment:
          return "Aprobado (${count(s)})";
        case OrderStatus.paymentSent:
          return "Pago enviado (${count(s)})";
        case OrderStatus.paid:
          return "Pagado (${count(s)})";
        case OrderStatus.delivered:
          return "Entregado (${count(s)})";
        default:
          return s.name;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {

        final selected = _statusFilter == status;

        return ChoiceChip(
          label: Text(label(status)),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _statusFilter = status;
            });
          },
        );

      }).toList(),
    );
  }

}