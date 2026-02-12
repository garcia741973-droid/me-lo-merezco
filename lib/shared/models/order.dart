enum OrderStatus {
  pending,            // carrito
  requested,          // enviado a validación
  approved,           // admin aprobó cotización
  approvedForPayment, // listo para pagar
  paymentSent,
  paid,
  delivered,
}



class Order {
  final int id;
  final double total;
  final OrderStatus status;

  Order({
    required this.id,
    required this.total,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      total: double.parse(json['total'].toString()),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
    );
  }
}



