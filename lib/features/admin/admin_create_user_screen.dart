import 'package:flutter/material.dart';

import '../../core/services/admin_user_service.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState
    extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();

  String _role = 'client';
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await AdminUserService.createUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _role,
        commissionRate:
            _role == 'seller'
                ? double.parse(_commissionCtrl.text)
                : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario creado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // indica éxito
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear usuario'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || !v.contains('@'))
                        ? 'Email inválido'
                        : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(
                    value: 'client',
                    child: Text('Cliente'),
                  ),
                  DropdownMenuItem(
                    value: 'seller',
                    child: Text('Vendedor'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                ],
                onChanged: (v) {
                  setState(() {
                    _role = v!;
                    _commissionCtrl.clear(); // 🔥 limpia al cambiar rol
                  });
                },
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
              if (_role == 'seller') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commissionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comisión (ej: 0.10)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (_role != 'seller') return null;
                    if (v == null || v.isEmpty) {
                      return 'Campo requerido';
                    }
                    final d = double.tryParse(v);
                    if (d == null || d < 0) {
                      return 'Número inválido';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
