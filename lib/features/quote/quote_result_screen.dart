import 'package:flutter/material.dart';

import '../../shared/models/quote.dart';

import '../../core/services/order_service.dart';


class QuoteResultScreen extends StatelessWidget {
  final Quote quote;

  const QuoteResultScreen({
    super.key,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final double importCosts = quote.shipping + quote.margin;
    final double total = quote.basePrice + importCosts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de cotización'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(
              'Producto',
              quote.productName,
            ),
            const Divider(),

            _row(
              'Precio base',
              '\$${quote.basePrice.toStringAsFixed(2)}',
            ),

            _row(
              'Costos por importación',
              '\$${importCosts.toStringAsFixed(2)}',
            ),

            const Divider(),

            _row(
              'Total',
              '\$${total.toStringAsFixed(2)}',
              isBold: true,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await OrderService.addQuote(
                      productName: quote.productName,
                      productUrl: null,
                      basePrice: quote.basePrice,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Producto agregado al carrito'),
                      ),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error agregando al carrito'),
                      ),
                    );
                  }
                },


                child: const Text('Agregar al carrito'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}
