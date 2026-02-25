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
  late Future<Map<String, List<dynamic>>> _groupedFuture;
  String? _selectedCategory; // null -> aún no inicializado; 'Todos' = show all

  @override
  void initState() {
    super.initState();
    _groupedFuture = _fetchAndGroupOffers();
  }

  // =========================
  // FETCH + GROUP
  // =========================
  Future<Map<String, List<dynamic>>> _fetchAndGroupOffers() async {
    final offersRes = await http.get(
      Uri.parse('https://me-lo-merezco-backend.onrender.com/offers'),
    );

    final categoriesRes = await http.get(
      Uri.parse('https://me-lo-merezco-backend.onrender.com/categories'),
    );

    if (offersRes.statusCode != 200 || categoriesRes.statusCode != 200) {
      throw Exception('Error cargando ofertas');
    }

    final offers = jsonDecode(offersRes.body);
    final categories = jsonDecode(categoriesRes.body);

    Map<int, String> categoryMap = {};
    for (var c in categories) {
      categoryMap[c['id']] = c['name'];
    }

    Map<String, List<dynamic>> grouped = {};

    for (var offer in offers) {
      final categoryId = offer['category_id'];
      final categoryName = categoryMap[categoryId] ?? 'Otros';

      grouped.putIfAbsent(categoryName, () => []);
      grouped[categoryName]!.add(offer);
    }

    // Asegura orden consistente: opcional, pero útil
    final ordered = Map<String, List<dynamic>>.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );

    return ordered;
  }

  // =========================
  // ADD TO CART
  // =========================
  Future<void> _addToCart(int offerId) async {
    final token = await AuthService().getToken();

    final res = await http.post(
      Uri.parse('https://me-lo-merezco-backend.onrender.com/orders/add-offer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'offer_id': offerId}),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.statusCode == 200 ? 'Agregado al carrito' : 'Error al agregar',
        ),
      ),
    );
  }

  // =========================
  // UI - CATEGORIES ROW
  // =========================
Widget _buildCategoriesGrid(List<String> categories) {
  final all = ['Todos', ...categories];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedCategory == null ? all.length : 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 160, // altura fija por carpeta
      ),
      itemBuilder: (context, index) {
        final name = _selectedCategory == null
              ? all[index]
              : _selectedCategory!;
        final selected = _selectedCategory == name;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = name;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: selected
                    ? Colors.deepPurple
                    : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder,
                  size: 48,
                  color: selected
                      ? Colors.deepPurple
                      : Colors.amber[700],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.deepPurple
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/logos/fondoGeneral.png',
              fit: BoxFit.cover,
            ),
          ),
          FutureBuilder<Map<String, List<dynamic>>>(
            future: _groupedFuture,
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

              final grouped = snapshot.data!;

              // Obtener lista de categorias (ordenada por las keys del mapa)
              final categories = grouped.keys.toList();

              // Inicializa selectedCategory la primera vez que hay datos
        // se elemina de momento      _selectedCategory ??= 'Todos';

              // Si está 'Todos' mostramos todo, si no, filtramos el mapa
              List<MapEntry<String, List<dynamic>>> entriesToShow;

              if (_selectedCategory == null) {
                entriesToShow = [];
              } else if (_selectedCategory == 'Todos') {
                entriesToShow = grouped.entries.toList();
              } else {
                entriesToShow = grouped.entries
                    .where((e) => e.key == _selectedCategory)
                    .toList();
              }

return CustomScrollView(
  slivers: [

    // Botón volver cuando una categoría está abierta
    if (_selectedCategory != null)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 16),
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text("Volver a categorías"),
          ),
        ),
      ),

    SliverToBoxAdapter(
      child: _buildCategoriesGrid(categories),
    ),
                  if (_selectedCategory == null)
  SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.folder_open,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Selecciona una categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  )
else
  SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, sectionIndex) {
          final entry = entriesToShow[sectionIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ...entry.value.map((o) {
                return Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (o['image_url'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: Image.network(
                            o['image_url'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
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
                            const SizedBox(height: 6),
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
                                label: const Text('Agregar al carrito'),
                                onPressed: () => _addToCart(o['id']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
        childCount: entriesToShow.length,
      ),
    ),
  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
