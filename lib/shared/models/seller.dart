class Seller {
  final int id;
  final String name;

  Seller({
    required this.id,
    required this.name,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'],
      name: json['name'],
    );
  }
}
