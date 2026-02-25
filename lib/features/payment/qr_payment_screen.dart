import 'package:flutter/material.dart';

import '../../core/services/order_service.dart';

class QrPaymentScreen extends StatelessWidget {
  final String orderId;
  final double amount;

  const QrPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago por QR'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Escanea el QR para realizar el pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Container(
              height: 220,
              width: 220,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Text(
                'QR',
                style: TextStyle(fontSize: 32),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Monto a pagar',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await OrderService.markPaymentSent(
                      int.parse(orderId),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pago enviado. Esperando confirmación del administrador.',
                        ),
                      ),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Error enviando el pago. Intenta nuevamente.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Ya pagué'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
