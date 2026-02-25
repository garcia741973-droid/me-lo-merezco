import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/services/auth_service.dart';

class ClientOfferDetailScreen extends StatelessWidget {
  final Map<String, dynamic> offer;

  const ClientOfferDetailScreen({
    super.key,
    required this.offer,
  });

  Future<void> _addToCart(
      BuildContext context, int offerId) async {
    final token = await AuthService().getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final res = await http.post(
      Uri.parse(
        'https://me-lo-merezco-backend.onrender.com/orders/add-offer',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'offer_id': offerId,
      }),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregado al carrito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar al carrito')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double price =
        double.tryParse(offer['price']?.toString() ?? '0') ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle oferta'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (offer['image_url'] != null)
              Image.network(
                offer['image_url'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (offer['description'] != null)
                    Text(offer['description']),
                  const SizedBox(height: 16),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon:
                          const Icon(Icons.add_shopping_cart),
                      label:
                          const Text('Agregar al carrito'),
                      onPressed: () =>
                          _addToCart(context, offer['id']),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
