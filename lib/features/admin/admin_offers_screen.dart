import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';

import 'admin_create_offer_screen.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  bool loading = true;
  List<dynamic> offers = [];

  int? expandedOfferId; 

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final token = await AuthService().getToken();
      final res = await http.get(
        Uri.parse(
          'https://me-lo-merezco-backend.onrender.com/admin/offers',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          offers = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleOffer(int id, bool value) async {
    final token = await AuthService().getToken();

    await http.patch(
      Uri.parse(
        'https://me-lo-merezco-backend.onrender.com/admin/offers/$id/active',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'active': value}),
    );

    _loadOffers();
  }

  Future<void> _deleteOffer(int id) async {
  final token = await AuthService().getToken();

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar oferta'),
      content: const Text(
          '¿Seguro que deseas eliminar esta oferta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  await http.delete(
    Uri.parse(
      'https://me-lo-merezco-backend.onrender.com/admin/offers/$id',
    ),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  _loadOffers();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOffers,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : offers.isEmpty
              ? const Center(
                  child: Text('No hay ofertas creadas'),
                )
              : ListView.builder(
                  itemCount: offers.length,
                  itemBuilder: (_, i) {
                    final o = offers[i];
                    return ListTile(
                      title: Text(o['title']),
                      subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o['description'] ?? '',
                          maxLines: expandedOfferId == o['id'] ? null : 2,
                          overflow: expandedOfferId == o['id']
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),

                        if ((o['description'] ?? '').length > 80)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (expandedOfferId == o['id']) {
                                  expandedOfferId = null;
                                } else {
                                  expandedOfferId = o['id'];
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                expandedOfferId == o['id']
                                    ? 'Ver menos'
                                    : 'Ver más',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                      trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      onPressed: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCreateOfferScreen(
              offer: o,
            ),
          ),
        );

        if (updated == true) {
          _loadOffers();
        }
      },
    ),
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () => _deleteOffer(o['id']),
    ),
    Switch(
      value: o['active'] == true,
      onChanged: (v) =>
          _toggleOffer(o['id'], v),
    ),
  ],
),

                    );
                  },
                ),
floatingActionButton: FloatingActionButton(
  child: const Icon(Icons.add),
  onPressed: () async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCreateOfferScreen(),
      ),
    );

    if (created == true) {
      _loadOffers();
    }
  },
),
    );
  }
}
