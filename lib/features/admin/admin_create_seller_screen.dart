import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/services/auth_service.dart';

class AdminCreateSellerScreen extends StatefulWidget {
  const AdminCreateSellerScreen({super.key});

  @override
  State<AdminCreateSellerScreen> createState() =>
      _AdminCreateSellerScreenState();
}

class _AdminCreateSellerScreenState extends State<AdminCreateSellerScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final documentCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final commissionCtrl = TextEditingController();
  bool isLoading = false;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _createSeller() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showMessage('Completa todos los campos');
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await AuthService().getToken();

      final res = await http.post(
        Uri.parse(
          'https://me-lo-merezco-backend.onrender.com/admin/users/seller',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': pass,
          'phone': phoneCtrl.text.trim(),
          'city': cityCtrl.text.trim(),
          'document_id': documentCtrl.text.trim(),
          'address': addressCtrl.text.trim(),
          'commission_rate': double.tryParse(commissionCtrl.text) ?? 0,
        }),
      );

      if (res.statusCode == 201) {
        _showMessage('Vendedor creado correctamente');
        Navigator.pop(context, true);
      } else if (res.statusCode == 409) {
        _showMessage('El email ya existe');
      } else {
        _showMessage('Error al crear vendedor');
      }
    } catch (_) {
      _showMessage('Error de conexión');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear vendedor')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: documentCtrl,
              decoration: const InputDecoration(labelText: 'Documento'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: commissionCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Comisión (%)'),
            ),

            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createSeller,
                      child: const Text('Crear vendedor'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
