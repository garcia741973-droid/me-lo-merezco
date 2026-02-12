import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';

import '../client/client_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../seller/seller_orders_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Completa todos los campos');
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await AuthService().login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage('Email o contraseña incorrectos');
        return;
      }

      // 🔑 Usuario ya autenticado: redirigir según rol (manteniendo tokens/roles)
      final user = AuthService().currentUser;
      if (user == null) {
        _showMessage('Error al obtener usuario');
        return;
      }

      Widget destination;
      switch (user.role) {
        case UserRole.admin:
          destination = const AdminHomeScreen();
          break;
        case UserRole.seller:
          destination = const SellerOrdersScreen();
          break;
        case UserRole.client:
        default:
          destination = const ClientHomeScreen();
      }

      // Reemplaza todo el stack (evita volver al login con back)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error al iniciar sesión. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text('Entrar'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
