import 'package:flutter/material.dart';

import '../../core/services/admin_user_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';

import '../auth/login_screen.dart';
import 'admin_create_seller_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _users = [];

  int? _updatingUserId; // evita doble toggle

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await AdminUserService.fetchUsers();
      if (!mounted) return;
      setState(() {
        _users = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    // 🔐 Protección: solo admin
    if (user == null || user.role != UserRole.admin) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        centerTitle: true,
        actions: [
          // ➕ CREAR VENDEDOR
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Crear vendedor',
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCreateSellerScreen(),
                ),
              );

              if (created == true) {
                _loadUsers();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ================= BODY =================

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No hay usuarios registrados',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final u = _users[index];
          final bool isActive = u['is_active'] == true;
          final bool updating = _updatingUserId == u['id'];

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                (u['name'] as String)
                    .trim()
                    .substring(0, 1)
                    .toUpperCase(),
              ),
            ),
            title: Text(u['name']),
            subtitle: Text(
              '${u['email']} · ${u['role'].toString().toUpperCase()}',
            ),
            trailing: Switch(
              value: isActive,
              onChanged: updating
                  ? null
                  : (value) async {
                      final action =
                          value ? 'activar' : 'desactivar';

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmar acción'),
                          content: Text(
                            '¿Seguro que deseas $action este usuario?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Confirmar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      setState(() =>
                          _updatingUserId = u['id']);

                      try {
                        await AdminUserService.setActive(
                          userId: u['id'],
                          isActive: value,
                        );

                        if (!mounted) return;
                        setState(() {
                          u['is_active'] = value;
                          _updatingUserId = null;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Usuario activado'
                                  : 'Usuario desactivado',
                            ),
                            backgroundColor: value
                                ? Colors.green
                                : Colors.orange,
                          ),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        setState(() =>
                            _updatingUserId = null);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error al actualizar el usuario',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
            ),
          );
        },
      ),
    );
  }
}
