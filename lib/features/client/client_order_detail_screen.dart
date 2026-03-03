import 'package:flutter/material.dart';
import '../../core/services/order_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';
import '../../shared/models/order.dart';
import '../payment/qr_payment_screen.dart';

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

class _ClientOrderDetailScreenState extends State<ClientOrderDetailScreen> {
  Order? _order;
  List<dynamic> _items = [];
  List<dynamic> _messages = [];

  bool _loading = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD DATA =================

    Future<void> _loadData() async {
    try {
      final order = await OrderService.fetchOrder(widget.orderId);
      final items =
          await OrderService.fetchOrderItems(widget.orderId);
      final messages =
          await OrderService.fetchOrderMessages(widget.orderId);

      setState(() {
        _order = order;
        _items = items;
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading order: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  // ================= REQUEST VALIDATION =================

  Future<void> _requestValidation() async {
    print("🔥 BOTÓN PRESIONADO 🔥");
  if (_order == null) return;

  setState(() => _requesting = true);

  try {
    final oldTotal = _order!.total;

    // 1️⃣ Recalcular quotes
    final newTotal =
        await OrderService.recalculateQuotes(_order!.id);

    // 2️⃣ Recargar pedido actualizado
    await _loadData();

    if (!mounted) return;

    // 3️⃣ Si el total cambió, pedir confirmación
    if (newTotal != oldTotal) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Actualización de cotización'),
          content: Text(
            'El tipo de cambio ha cambiado.\n\n'
            'Total anterior: Bs ${oldTotal.toStringAsFixed(2)}\n'
            'Nuevo total: Bs ${newTotal.toStringAsFixed(2)}\n\n'
            '¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _requesting = false);
        return;
      }
    }

    // 4️⃣ Enviar solicitud
    await OrderService.requestOrderValidation(_order!.id);

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitud enviada correctamente'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _requesting = false);
    }
  }
}

  // ================= UI =================

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

print("REQUESTING STATE: $_requesting");
print("ORDER STATUS: ${_order!.status}");
print("IS CLIENT: $isClient");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del pedido'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logos/fondoGeneral.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(),
                  const SizedBox(height: 24),

                  const Text(
                    'Ítems del pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                      Flexible(
                        fit: FlexFit.loose,
                        child: _items.isEmpty
                        ? const Center(
                            child: Text('No hay ítems en este pedido'),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'] ?? '',
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Precio: \$${item['price']}',
                                        style: const TextStyle(
                                          color:
                                              Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment:
                                            Alignment.centerRight,
                                        child: item['status'] ==
                                                    'pending' &&
                                                isAdmin
                                            ? Row(
                                                mainAxisSize:
                                                    MainAxisSize
                                                        .min,
                                                children: [
                                                  IconButton(
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .check,
                                                      color:
                                                          Colors
                                                              .green,
                                                    ),
                                                    onPressed:
                                                        () async {
                                                      await OrderService
                                                          .approveItem(
                                                              item[
                                                                  'id']);
                                                      await _loadData();
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .close,
                                                      color:
                                                          Colors
                                                              .red,
                                                    ),
                                                    onPressed:
                                                        () async {
                                                      await OrderService
                                                          .rejectItem(
                                                              item[
                                                                  'id']);
                                                      await _loadData();
                                                    },
                                                  ),
                                                ],
                                              )

                                            : Text(
                                                _formatItemStatus(
                                                    item[
                                                        'status']),
                                                style:
                                                    TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                  color:
                                                      _itemStatusColor(
                                                          item[
                                                              'status']),
                                                ),
                                              ),
                                      ),

                                  const SizedBox(height: 8),
                                  ..._buildItemMessages(item),

                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  _statusMessage(_order!.status),

                  const SizedBox(height: 12),

// ================= BOTÓN PAGAR =================

if (isClient &&
    (_order!.status == OrderStatus.approvedForPayment ||
     _order!.status == OrderStatus.paymentSent))
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QrPaymentScreen(
              orderId: _order!.id,
            ),
          ),
        );
      },
      child: Text(
        _order!.status == OrderStatus.approvedForPayment
            ? 'Pagar anticipo'
            : 'Pagar saldo',
      ),
    ),
  ),

const SizedBox(height: 12),

                  if (isClient &&
                      _order!.status ==
                          OrderStatus.pending)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requesting
                            ? null
                            : _requestValidation,
                        child: _requesting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Enviar solicitud'),
                      ),
                    ),

                  const SizedBox(height: 12),

                  if (isClient)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                            'Volver a mis pedidos'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

List<Widget> _buildItemMessages(dynamic item) {
  final itemMessages =
      _messages.where((m) => m['item_id'] == item['id']).toList();

  if (itemMessages.isEmpty) return [];

  return itemMessages.map<Widget>((msg) {
    final isActionable =
        msg['action_required'] == true &&
        msg['action_type'] == 'accept_condition' &&
        msg['sender_role'] == 'admin';

    final List<dynamic>? requiredFields =
        msg['required_fields'];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Observación del administrador:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 6),

          Text(msg['message'] ?? ''),

          if (msg['adjusted_price'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Nuevo precio: Bs ${msg['adjusted_price']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // 🔹 Mostrar campos requeridos informativamente
          if (requiredFields != null &&
              requiredFields.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información requerida:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...requiredFields.map((f) => Text(
                        "• ${f['label']}",
                        style: const TextStyle(
                            color: Colors.black87),
                      )),
                ],
              ),
            ),

          if (isActionable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          Map<String, dynamic>
                              filledFields = {};

                          if (requiredFields != null &&
                              requiredFields
                                  .isNotEmpty) {
                            final formResult =
                                await _showDynamicForm(
                                    requiredFields);

                            if (formResult == null)
                              return;

                            filledFields =
                                formResult;
                          }

                          final result =
                              await OrderService
                                  .acceptOrderMessage(
                            msg['id'],
                            filledFields:
                                filledFields,
                          );

                          await _loadData();

                          if (!mounted) return;

                          ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Condición aceptada'),
                            ),
                          );

                          if (result[
                                  'order_status'] ==
                              'approvedForPayment') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    QrPaymentScreen(
                                  orderId:
                                      _order!.id,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error: $e'),
                            ),
                          );
                        }
                      },
                      child:
                          const Text('Aceptar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          await OrderService
                              .rejectOrderMessage(
                                  msg['id']);

                          await _loadData();

                          if (!mounted) return;

                          ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Condición rechazada'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error: $e'),
                            ),
                          );
                        }
                      },
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.red,
                      ),
                      child:
                          const Text('Rechazar'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }).toList();
}

Future<Map<String, dynamic>?> _showDynamicForm(
    List<dynamic> fields) async {

  final Map<String, TextEditingController>
      controllers = {};

  for (var f in fields) {
    controllers[f['key']] =
        TextEditingController();
  }

  return await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title:
            const Text('Información requerida'),
        content: SingleChildScrollView(
          child: Column(
            children: fields.map((f) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                        bottom: 12),
                child: TextField(
                  controller:
                      controllers[f['key']],
                  decoration:
                      InputDecoration(
                    labelText:
                        f['label'],
                    border:
                        const OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, null),
            child:
                const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Map<String, dynamic>
                  result = {};

              for (var f in fields) {
                final value =
                    controllers[f['key']]!
                        .text
                        .trim();

                if (value.isEmpty) {
                  return;
                }

                result[f['key']] =
                    value;
              }

              Navigator.pop(
                  context, result);
            },
            child:
                const Text('Aceptar'),
          ),
        ],
      );
    },
  );
}

  // ================= UI HELPERS =================

  Widget _headerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _row('Pedido ID', _order!.id.toString()),
            const Divider(),
            _row(
              'Total',
              '\$${_order!.total.toStringAsFixed(2)}',
            ),
            _row(
              'Estado',
              _formatStatus(_order!.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.bold),
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
      case OrderStatus.rejected:
        return const Text(
          'Todos los productos fueron rechazados.',
          style: TextStyle(color: Colors.red),
        );
    }
  }

  String _formatStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En carrito';
      case OrderStatus.requested:
        return 'Solicitud enviada';
      case OrderStatus.approvedForPayment:
        return 'Aprobado para pago';
      case OrderStatus.paymentSent:
        return 'Pago enviado';
      case OrderStatus.paid:
        return 'Pagado';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.rejected:
        return 'Rechazado';
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
}
