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
        sellerId: selectedSellerId,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage('El email ya está registrado');
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [

          // 🌿 Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/logos/fondoGeneral.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [

                  const SizedBox(height: 50),

                  const Text(
                    "Crear cuenta",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _inputField(nameCtrl, "Nombre"),
                  const SizedBox(height: 14),

                  _inputField(
                    emailCtrl,
                    "Email",
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  loadingSellers
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        )
                      : DropdownButtonFormField<int>(
                          value: selectedSellerId,
                          decoration: _inputDecoration(
                            "Vendedor (opcional)",
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

                  const SizedBox(height: 14),

                  _inputField(passCtrl, "Contraseña", obscure: true),
                  const SizedBox(height: 14),

                  _inputField(pass2Ctrl, "Confirmar contraseña", obscure: true),

                  const SizedBox(height: 30),

                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAEDFC8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "Crear cuenta",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 INPUT STYLE
  Widget _inputField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}