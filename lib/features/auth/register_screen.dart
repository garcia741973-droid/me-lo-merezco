import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';
import '../../shared/models/seller.dart';
import '../client/client_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();

  bool isLoading = false;

  // 🔹 NUEVO: vendedores dinámicos
  List<Seller> sellers = [];
  bool loadingSellers = true;
  int? selectedSellerId;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ===============================
  // CARGAR VENDEDORES (OPCIÓN 2)
  // ===============================
  Future<void> _loadSellers() async {
    try {
      final res = await http.get(
        Uri.parse('https://me-lo-merezco-backend.onrender.com/sellers'),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          sellers = data.map((e) => Seller.fromJson(e)).toList();
          loadingSellers = false;
        });
      } else {
        setState(() => loadingSellers = false);
      }
    } catch (_) {
      setState(() => loadingSellers = false);
    }
  }

  // ===============================
  // REGISTER
  // ===============================
  Future<void> _register() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final pass2 = pass2Ctrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      _showMessage('Completa todos los campos');
      return;
    }

    if (pass != pass2) {
      _showMessage('Las contraseñas no coinciden');
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await AuthService().register(
        name: name,
        email: email,
        password: pass,
        sellerId: selectedSellerId, // 👈 opcional
      );

      if (!mounted) return;

      if (!success) {
        _showMessage('El email ya está registrado');
        return;
      }

      // Registro OK → ir al home del cliente
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        (_) => false,
      );
    } catch (_) {
      _showMessage('No se pudo registrar. Intenta más tarde.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        child: Padding(
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
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),

              // 🔽 DROPDOWN DINÁMICO DE VENDEDORES
              loadingSellers
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    )
                  : DropdownButtonFormField<int>(
                      value: selectedSellerId,
                      decoration: const InputDecoration(
                        labelText: 'Vendedor (opcional)',
                        helperText:
                            'Si no eliges uno, se asignará automáticamente',
                      ),
                      items: sellers.map((seller) {
                        return DropdownMenuItem<int>(
                          value: seller.id,
                          child: Text(seller.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSellerId = value;
                        });
                      },
                    ),
              const SizedBox(height: 12),

              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: pass2Ctrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirmar contraseña'),
              ),
              const SizedBox(height: 20),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        child: const Text('Crear cuenta'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
