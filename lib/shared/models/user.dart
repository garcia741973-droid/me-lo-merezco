enum UserRole {
  client,
  seller,
  admin,
}

class User {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final double? commissionRate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.commissionRate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      commissionRate: json['commission_rate'] != null
          ? double.tryParse(json['commission_rate'].toString())
          : null,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }
}
