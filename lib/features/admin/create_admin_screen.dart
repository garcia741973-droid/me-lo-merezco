import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> _createAdmin() async {

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _show("Completa todos los campos");
      return;
    }

    setState(() => loading = true);

    try {

      await AdminService.createAdmin(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

    } catch (e) {

      _show("Error creando administrador");

    } finally {

      if (mounted) {
        setState(() => loading = false);
      }

    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Administrador"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña",
              ),
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createAdmin,
                    child: const Text("Crear administrador"),
                  )
          ],
        ),
      ),
    );
  }
}