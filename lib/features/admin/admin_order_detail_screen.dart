import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';
import '../../shared/models/order.dart';

import 'widgets/admin_item_review_sheet.dart';

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
  List<dynamic> _payments = [];
  double _paidSoFar = 0; 
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _loadData() async {
  try {
    final data =
        await OrderService.fetchAdminOrderDashboard(widget.orderId);

    final orderJson = data['order'];
    final items = data['items'] as List<dynamic>;
    final payments = data['payments'] as List<dynamic>;
    final financial = data['financial'];

    setState(() {
      _order = Order.fromJson(orderJson);
      _items = items;
      _payments = payments;
      _paidSoFar =
          double.parse(financial['verified_total'].toString());
      _loading = false;
    });
  } catch (e) {
    debugPrint('Admin dashboard load error: $e');
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

Future<void> _showConditionalDialog(int itemId) async {
  final messageController = TextEditingController();
  final priceController = TextEditingController();

  bool requestSize = false;
  bool requestColor = false;
  bool requestNotes = false;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Rechazo condicional'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje al cliente',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio ajustado (opcional)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Solicitar al cliente:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    value: requestSize,
                    onChanged: (v) =>
                        setStateDialog(() => requestSize = v ?? false),
                    title: const Text('Talla'),
                  ),
                  CheckboxListTile(
                    value: requestColor,
                    onChanged: (v) =>
                        setStateDialog(() => requestColor = v ?? false),
                    title: const Text('Color'),
                  ),
                  CheckboxListTile(
                    value: requestNotes,
                    onChanged: (v) =>
                        setStateDialog(() => requestNotes = v ?? false),
                    title: const Text('Observaciones adicionales'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('El mensaje es obligatorio')),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Enviar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true) {
    try {
      double? adjustedPrice;

      if (priceController.text.isNotEmpty) {
        adjustedPrice =
            double.tryParse(priceController.text.replaceAll(',', '.'));
      }

      List<Map<String, dynamic>> requiredFields = [];

      if (requestSize) {
        requiredFields.add({
          "key": "size",
          "label": "Talla",
          "type": "text",
        });
      }

      if (requestColor) {
        requiredFields.add({
          "key": "color",
          "label": "Color",
          "type": "text",
        });
      }

      if (requestNotes) {
        requiredFields.add({
          "key": "notes",
          "label": "Observaciones",
          "type": "text",
        });
      }

      await OrderService.conditionalRejectItem(
        itemId: itemId,
        message: messageController.text.trim(),
        adjustedPrice: adjustedPrice,
        requiredFields: requiredFields,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Observación enviada al cliente')),
      );
    } catch (e) {
      debugPrint('Error conditional reject: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error enviando observación')),
      );
    }
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
      body: Center(child: Text('Pedido no encontrado')),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: Text('Pedido #${_order!.id}'),
      centerTitle: true,
    ),
body: SafeArea(
  child: ListView(
    padding: const EdgeInsets.all(20),
    children: [

      Text(
        'Estado actual: ${_order!.status.name}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 16),

      _buildTimeline(),

      const SizedBox(height: 16),

      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Resumen financiero',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              Text('Total: Bs ${_order!.total.toStringAsFixed(2)}'),
              Text('Pagado: Bs ${_paidSoFar.toStringAsFixed(2)}'),

              Text(
                'Saldo: Bs ${(_order!.total - _paidSoFar).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

            ],
          ),
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

      ..._items.map((item) {

      debugPrint(item.toString());  

        final specs = item['client_specs'] ?? {};

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
                item['product_name'] ??
                item['offer_title'] ??
                'Producto',
              ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text('Precio: \$${item['price']}'),
                Text('Estado: ${item['status']}'),

                const SizedBox(height: 4),

                Text('Cantidad: ${item['quantity'] ?? 1}'),

                if (specs['size'] != null)
                  Text('Talla: ${specs['size']}'),

                if (specs['color'] != null)
                  Text('Color: ${specs['color']}'),

                if (specs['notes'] != null &&
                    specs['notes'].toString().isNotEmpty)
                  Text('Observaciones: ${specs['notes']}'),

                if (item['product_url'] != null)
                  Text(
                    'Producto: ${item['product_url']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),

              ],
            ),

            trailing: item['status'] == 'requested'
                ? PopupMenuButton<String>(
                    onSelected: (value) async {

                      if (value == 'approve') {
                        await _approve(item['id']);
                      }

                      else if (value == 'reject') {
                        await _reject(item['id']);
                      }

                      else if (value == 'conditional') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useRootNavigator: true,
                          builder: (_) => AdminItemReviewSheet(
                            item: item,
                            onUpdated: () async {
                              await _loadData();
                            },
                          ),
                        );
                      }

                    },

                    itemBuilder: (context) => const [

                      PopupMenuItem(
                        value: 'approve',
                        child: Text('Aprobar'),
                      ),

                      PopupMenuItem(
                        value: 'reject',
                        child: Text('Rechazar'),
                      ),

                      PopupMenuItem(
                        value: 'conditional',
                        child: Text('Rechazo condicional'),
                      ),

                    ],
                  )
                : null,
          ),
        );

      }).toList(),

                const SizedBox(height: 20),

          const Text(
            'Pagos recibidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (_payments.isEmpty)
            const Text('No hay comprobantes enviados por el cliente.')
          else
            ..._payments.map((p) {

              final amount =
                  double.tryParse(p['amount'].toString()) ?? 0;

              final status = p['status'] ?? '';
              final proofUrl = p['proof_image_url'];

              final isPending = status == 'pending_verification';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('Pago Bs ${amount.toStringAsFixed(2)}'),
                  subtitle: Text('Estado: $status'),

                  leading: proofUrl != null
                      ? IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () {
                            _showFullImage(proofUrl);
                          },
                        )
                      : null,

                    trailing: isPending
                        ? ElevatedButton(
                            onPressed: () async {

                              await OrderService.confirmPayment(_order!.id);

                              await _loadData();

                            },
                            child: const Text('Confirmar pago'),
                          )
                      : const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                ),
              );

            }).toList(),

            const SizedBox(height: 20),

              Builder(
                builder: (context) {

                  final finalPaymentVerified = _payments.any(
                    (p) => p['payment_type'] == 'final' && p['status'] == 'verified',
                  );

                  if (!finalPaymentVerified) {
                    return const SizedBox();
                  }

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {

                      await OrderService.markDelivered(_order!.id);

                      await _loadData();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pedido marcado como entregado'),
                        ),
                      );

                    },
                    child: const Text('Marcar como entregado'),
                  );

                },
              ),

            const SizedBox(height: 20),

              Builder(
                builder: (context) {

                  final firstPaymentVerified = _payments.any(
                    (p) => p['payment_type'] == 'initial' && p['status'] == 'verified',
                  );

                  final finalPaymentExists = _payments.any(
                    (p) => p['payment_type'] == 'final',
                  );

                  if (!firstPaymentVerified || finalPaymentExists) {
                    return const SizedBox();
                  }

                  return ElevatedButton(
                    onPressed: () async {

                      await OrderService.requestFinalPayment(_order!.id);

                      await _loadData();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Solicitud de segundo pago enviada'),
                        ),
                      );

                    },
                    child: const Text('Solicitar segundo pago'),
                  );

                },
              ),

    ],
  ),
),
  );
}

void _showFullImage(String imageUrl) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}


Widget _buildTimeline() {
  if (_order == null) return const SizedBox();

Widget row(String label, DateTime? date) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          date != null
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: date != null ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                date != null
                    ? date.toLocal().toString().substring(0, 16)
                    : '-',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          row('Solicitado', _order!.requestedAt),

          row('Aprobado para 1er pago', _order!.approvedForPaymentAt),

          row('Comprobante enviado 1er pago', _order!.paymentSentAt),

          row(
            '1er pago verificado',
            _payments.any(
              (p) => p['payment_type'] == 'initial' && p['status'] == 'verified'
            )
                ? DateTime.tryParse(
                    _payments
                        .firstWhere(
                          (p) => p['payment_type'] == 'initial'
                                && p['status'] == 'verified'
                        )['verified_at']
                        .toString(),
                  )
                : null,
          ),

          row(
            'Aprobado para 2do pago',
            _payments.any((p) => p['payment_type'] == 'final')
                ? DateTime.tryParse(
                    _payments
                        .firstWhere((p) => p['payment_type'] == 'final')['created_at']
                        .toString(),
                  )
                : null,
          ),

          row(
            '2do pago enviado',
            _payments.any((p) => p['payment_type'] == 'final')
                ? DateTime.tryParse(
                    _payments
                        .firstWhere((p) => p['payment_type'] == 'final')['created_at']
                        .toString())
                : null,
          ),

          row(
            '2do pago verificado',
            _payments.any(
              (p) => p['payment_type'] == 'final' && p['status'] == 'verified',
            )
                ? DateTime.tryParse(
                    _payments
                        .firstWhere((p) =>
                            p['payment_type'] == 'final' &&
                            p['status'] == 'verified')['verified_at']
                        .toString(),
                  )
                : null,
          ),

          row(
            'Entregado',
            _order!.deliveredAt,
          ),
        ],
      ),
    ),
  );
}

}
