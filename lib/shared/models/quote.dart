class Quote {
  final String productName;
  final double basePrice;
  final double shipping;
  final double margin;

  Quote({
    required this.productName,
    required this.basePrice,
    required this.shipping,
    required this.margin,
  });

  double get total => basePrice + shipping + margin;
}
