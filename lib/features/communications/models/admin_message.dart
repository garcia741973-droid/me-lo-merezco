class AdminMessage {
  final int id;
  final int senderId;
  final int? receiverId;
  final String message;
  final bool isBroadcast;
  final DateTime createdAt;
  final DateTime? readAt;

  AdminMessage({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.message,
    required this.isBroadcast,
    required this.createdAt,
    this.readAt,
  });

  factory AdminMessage.fromJson(Map<String, dynamic> json) {
    return AdminMessage(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      isBroadcast: json['is_broadcast'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
    );
  }
}