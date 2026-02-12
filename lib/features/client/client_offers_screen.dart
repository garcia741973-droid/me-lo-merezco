import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';

class ClientOffersScreen extends StatefulWidget {
  const ClientOffersScreen({super.key});

  @override
  State<ClientOffersScreen> createState() => _ClientOffersScreenState();
}

class _ClientOffersScreenState extends State<ClientOffersScreen> {
  late Future<List<dynamic>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchOffers();
  }

  // =========================
  // FETCH OFFERS (PUBLIC)
  // =========================
  Future<List<dynamic>> _fetchOffers() async {
    final res = await http.get(
      Uri.parse(
        'https://me-lo-merezco-backend.onrender.com/offers',
      ),
    );

    if (res.statusCode != 200) {
      throw Exception('Error cargando ofertas');
    }

    return jsonDecode(res.body);
  }

  // =========================
  // ADD OFFER TO CART
  // =========================
  Future<void> _addToCart(int offerId) async {
    final token = await AuthService().getToken();

    if (token == null) {
      if (!mounted) return;
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

    if (!mounted) return;

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

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _offersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error cargando ofertas'),
            );
          }

          final offers = snapshot.data!;
          if (offers.isEmpty) {
            return const Center(
              child: Text('No hay ofertas disponibles'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: offers.length,
            itemBuilder: (_, i) {
              final o = offers[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (o['image_url'] != null)
                      Image.network(
                        o['image_url'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (o['description'] != null) ...[
                            const SizedBox(height: 6),
                            Text(o['description']),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            '\$${o['price']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_shopping_cart),
                              label:
                                  const Text('Agregar al carrito'),
                              onPressed: () =>
                                  _addToCart(o['id']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
