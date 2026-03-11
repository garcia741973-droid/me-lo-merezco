import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {

  final String email;
  final String code;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<NewPasswordScreen> createState() =>
      _NewPasswordScreenState();
}

class _NewPasswordScreenState
    extends State<NewPasswordScreen> {

  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> _setPassword() async {

    final password = passwordController.text.trim();

    if (password.length < 6) {
      _show("La contraseña debe tener mínimo 6 caracteres");
      return;
    }

    setState(() => loading = true);

    try {

      final ok = await AuthService().setNewPassword(
        widget.email,
        widget.code,
        password,
      );

      if (!mounted) return;

      if (!ok) {
        _show("Error cambiando contraseña");
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );

    } catch (_) {

      _show("Error del servidor");

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
      appBar: AppBar(title: const Text("Nueva contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            const Text(
              "Ingresa tu nueva contraseña",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nueva contraseña",
              ),
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _setPassword,
                      child: const Text("Guardar contraseña"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}