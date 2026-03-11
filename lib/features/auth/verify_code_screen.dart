import 'package:flutter/material.dart';
import 'new_password_screen.dart';
import '../../core/services/auth_service.dart';

class VerifyCodeScreen extends StatefulWidget {

  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() =>
      _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {

  final codeController = TextEditingController();

  bool loading = false;

  Future<void> _verify() async {

    final code = codeController.text.trim();

    if (code.isEmpty) {
      _show("Ingresa el código");
      return;
    }

    setState(() => loading = true);

    try {

      final res = await AuthService().verifyResetCode(
        widget.email,
        code,
      );

      if (!mounted) return;

      if (!res) {
        _show("Código inválido o expirado");
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewPasswordScreen(
            email: widget.email,
            code: code,
          ),
        ),
      );

    } catch (_) {

      _show("Error verificando código");

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
      appBar: AppBar(title: const Text("Verificar código")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            const Text(
              "Ingresa el código que recibiste",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Código",
              ),
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verify,
                      child: const Text("Verificar"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}