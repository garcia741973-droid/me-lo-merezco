import 'package:flutter/material.dart';
import '../../core/services/admin_user_service.dart';

class AdminCreateOperatorScreen extends StatefulWidget {
  const AdminCreateOperatorScreen({super.key});

  @override
  State<AdminCreateOperatorScreen> createState() =>
      _AdminCreateOperatorScreenState();
}

class _AdminCreateOperatorScreenState
    extends State<AdminCreateOperatorScreen> {

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final documentCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

  bool loading = false;

  Future<void> _create() async {

    if (
    nameCtrl.text.isEmpty ||
    emailCtrl.text.isEmpty ||
    passCtrl.text.isEmpty
    )  {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos')),
      );
      return;
    }

    setState(() => loading = true);

    try {

      await AdminUserService.createUser(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        role: 'operador',
      );

      if (!mounted) return;

      Navigator.pop(context, true);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    } finally {

      if (mounted) {
        setState(() => loading = false);
      }

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear operador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),

                const SizedBox(height: 12),

                TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Contraseña',
                ),
                ),

                const SizedBox(height: 12),

                TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                    labelText: 'Teléfono',
                ),
                ),

                const SizedBox(height: 12),

                TextField(
                controller: documentCtrl,
                decoration: const InputDecoration(
                    labelText: 'Documento',
                ),
                ),

                const SizedBox(height: 12),

                TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(
                    labelText: 'Ciudad',
                ),
                ),

                const SizedBox(height: 12),

                TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                    labelText: 'Dirección',
                ),
                ),            

            const SizedBox(height: 24),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _create,
                      child: const Text('Crear operador'),
                    ),
                  ),

          ],
        ),
      ),
    );
  }
}