import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final emailController = TextEditingController();
  bool loading = false;

  Future<void> _sendCode() async {

    final email = emailController.text.trim();

    if (email.isEmpty) {
      _show("Ingresa tu email");
      return;
    }

    setState(() => loading = true);

    try {

      await AuthService().requestResetCode(email);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: email),
        ),
      );

    } catch (e) {

      _show("Error enviando código");

    } finally {

      if (mounted) setState(() => loading = false);

    }

  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            const Text(
              "Ingresa tu email y recibirás un código",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendCode,
                      child: const Text("Enviar código"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}