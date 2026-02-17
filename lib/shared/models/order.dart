enum OrderStatus {
  pending,
  requested,
  approvedForPayment,
  paymentSent,
  paid,
  delivered,
  rejected,
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



