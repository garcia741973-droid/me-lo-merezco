import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import 'login_screen.dart';
import '../client/client_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../seller/seller_orders_screen.dart';
import '../../shared/models/user.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Intentamos recuperar y validar token / user desde AuthService
      final ok = await AuthService().fetchCurrentUserFromToken();
      if (!mounted) return;

      if (ok) {
        final user = AuthService().currentUser;
        // Redirigir según rol
        Widget destination;
        switch (user!.role) {
          case UserRole.admin:
            destination = const AdminHomeScreen();
            break;
          case UserRole.seller:
            destination = const SellerOrdersScreen();
            break;
          case UserRole.client:
          default:
            destination = ClientHomeScreen();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
        return;
      } else {
        // Token inválido o no hay token -> seguir a Login/Register
        setState(() {
          _loading = false;
        });
      }
    } catch (_) {
  if (!mounted) return;
  setState(() {
    _loading = false;
  });
}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Me lo merezco')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido a Me lo merezco',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Iniciar sesión')),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
                // o MaterialPageRoute(builder: (_) => const RegisterScreen())
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Crear cuenta')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
