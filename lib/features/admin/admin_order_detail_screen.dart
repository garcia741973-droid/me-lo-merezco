import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';
import '../../shared/models/order.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends State<AdminOrderDetailScreen> {
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
      debugPrint('Admin load error: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _approve(int itemId) async {
    await OrderService.approveItem(itemId);
    await _loadData();
  }

  Future<void> _reject(int itemId) async {
    await OrderService.rejectItem(itemId);
    await _loadData();
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
        body: Center(child: Text('Pedido no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${_order!.id}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado actual: ${_order!.status.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Artículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(item['product_name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Precio: \$${item['price']}'),
                          Text('Estado: ${item['status']}'),
                        ],
                      ),
                      trailing: item['status'] == 'pending'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _approve(item['id']),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _reject(item['id']),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
