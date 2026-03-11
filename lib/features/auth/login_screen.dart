import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';

import '../client/client_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../seller/seller_orders_screen.dart';
import '../superadmin/superadmin_home_screen.dart';
import '../operator/operator_home_screen.dart';

import '../auth/forgot_password_screen.dart';

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

      final user = AuthService().currentUser;
      if (user == null) {
        _showMessage('Error al obtener usuario');
        return;
      }

      Widget destination;

      switch (user.role) {

        case UserRole.superadmin:
          destination = const SuperAdminHomeScreen();
          break;

        case UserRole.admin:
          destination = const AdminHomeScreen();
          break;

        case UserRole.operador:
          destination = const OperatorHomeScreen();
          break;

        case UserRole.seller:
          destination = const SellerOrdersScreen();
          break;

        case UserRole.client:
        default:
          destination = const ClientHomeScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (_) {
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
        extendBodyBehindAppBar: true,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: Stack(
        children: [

          // 🌿 Fondo real visible
          Positioned.fill(
            child: Image.asset(
              'assets/logos/fondoGeneral.png',
              fit: BoxFit.cover,
            ),
          ),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [

                  const SizedBox(height: 60),

                  const Text(
                    "Iniciar sesión",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // EMAIL
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // PASSWORD
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAEDFC8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "Entrar",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 60),

                  // 🔱 Logo minimalista abajo
                  Image.asset(
                    "assets/logos/logo_minimalista.png",
                    width: MediaQuery.of(context).size.width * 0.50,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}