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

  // NUEVOS CAMPOS (opcionales)
  final DateTime? requestedAt;
  final DateTime? approvedForPaymentAt;
  final DateTime? paymentSentAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final DateTime? rejectedAt;

  Order({
    required this.id,
    required this.total,
    required this.status,
    this.requestedAt,
    this.approvedForPaymentAt,
    this.paymentSentAt,
    this.paidAt,
    this.deliveredAt,
    this.rejectedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return Order(
      id: json['id'] as int,
      total: double.parse(json['total'].toString()),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      requestedAt: parseDate(json['requested_at']),
      approvedForPaymentAt: parseDate(json['approved_for_payment_at']),
      paymentSentAt: parseDate(json['payment_sent_at']),
      paidAt: parseDate(json['paid_at']),
      deliveredAt: parseDate(json['delivered_at']),
      rejectedAt: parseDate(json['rejected_at']),
    );
  }
}



