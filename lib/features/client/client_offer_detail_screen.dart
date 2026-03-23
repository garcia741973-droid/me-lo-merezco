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

    // 🔒 BLOQUEO VISITANTE
    if (AuthService().currentUser == null) {
      _showAuthRequiredDialog(context);
      return;
    }

    final token = await AuthService().getToken();

    if (token == null) {
      _showAuthRequiredDialog(context);
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

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.statusCode == 200
              ? 'Agregado al carrito'
              : 'Error al agregar al carrito',
        ),
      ),
    );
  }

    void _showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Acceso requerido"),
        content: const Text(
          "Lo sentimos esta función es solo permitido para usuarios registrados, por favor inicia sesión o registrate. Gracias",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text("Iniciar sesión"),
          ),
        ],
      ),
    );
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
                    'Bs ${price.toStringAsFixed(2)}',
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
