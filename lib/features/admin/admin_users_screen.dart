import 'package:flutter/material.dart';

import '../../core/services/admin_user_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';

import '../auth/login_screen.dart';
import 'admin_create_seller_screen.dart';
import 'admin_create_operator_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _users = [];

  String _roleFilter = 'all';  

  int? _updatingUserId;

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

    if (user == null || user.role != UserRole.admin) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        centerTitle: true,
        actions: [
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
              icon: const Icon(Icons.engineering),
              tooltip: 'Crear operador',
              onPressed: () async {

                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminCreateOperatorScreen(),
                  ),
                );

                if (created == true) {
                  _loadUsers();
                }

              },
            ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por rol',
            onSelected: (value) {
              setState(() {
                _roleFilter = value;
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'all',
                child: Text('Todos'),
              ),
              PopupMenuItem<String>(
                value: 'admin',
                child: Text('Admins'),
              ),
              PopupMenuItem<String>(
                value: 'seller',
                child: Text('Vendedores'),
              ),
              PopupMenuItem<String>(
                value: 'operador',
                child: Text('Operadores'),
              ),
              PopupMenuItem<String>(
                value: 'client',
                child: Text('Clientes'),
              ),
              PopupMenuItem<String>(
                value: 'superadmin',
                child: Text('Super Admin'),
              ),
            ],
          ),

        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados'));
    }

      final filteredUsers = _roleFilter == 'all'
          ? _users
          : _users.where((u) => u['role'] == _roleFilter).toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text('No hay usuarios para este filtro'),
          );
        }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        itemCount: filteredUsers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final u = filteredUsers[index];
          final bool isActive = u['is_active'] == true;
          final bool updating = _updatingUserId == u['id'];

          return ExpansionTile(
            leading: CircleAvatar(
              child: Text(
                (u['name'] as String).trim().substring(0, 1).toUpperCase(),
              ),
            ),
            title: Text(u['name']),
            subtitle: Text(
              '${u['email']} · ${u['role'].toString().toUpperCase()}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (u['phone'] != null &&
                        u['phone'].toString().trim().isNotEmpty)
                      Text('Teléfono: ${u['phone']}'),

                    if (u['document_id'] != null &&
                        u['document_id'].toString().trim().isNotEmpty)
                      Text('Documento: ${u['document_id']}'),

                    if (u['city'] != null &&
                        u['city'].toString().trim().isNotEmpty)
                      Text('Ciudad: ${u['city']}'),

                    if (u['address'] != null &&
                        u['address'].toString().trim().isNotEmpty)
                      Text('Dirección: ${u['address']}'),

                    if (u['commission_rate'] != null)
                      Text('Comisión: ${u['commission_rate']} %'),

                    Text(
                      'Estado: ${isActive ? 'Activo' : 'Inactivo'}',
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await _openEditDialog(u);
                            _loadUsers();
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // confirmación + delete
                          },
                        ),

                        Switch(
                          value: isActive,
                          onChanged: updating
                              ? null
                              : (value) async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Confirmar acción'),
                                      content: Text(
                                        value
                                            ? '¿Activar usuario?'
                                            : '¿Desactivar usuario?',
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

                                  setState(() => _updatingUserId = u['id']);

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
                                  } catch (_) {
                                    if (!mounted) return;
                                    setState(() => _updatingUserId = null);
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditDialog(dynamic userData) async {
    final role = userData['role'];

    final TextEditingController commissionController =
        TextEditingController(
      text: userData['commission_rate']?.toString() ?? '',
    );

    final TextEditingController phoneCtrl =
        TextEditingController(text: userData['phone'] ?? '');

    final TextEditingController documentCtrl =
        TextEditingController(text: userData['document_id'] ?? '');

    final TextEditingController cityCtrl =
        TextEditingController(text: userData['city'] ?? '');

    final TextEditingController addressCtrl =
        TextEditingController(text: userData['address'] ?? '');

    int? selectedSellerId = userData['seller_id'];

    final sellers =
        _users.where((u) => u['role'] == 'seller').toList();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (role == 'client')
              DropdownButtonFormField<int>(
                value: selectedSellerId,
                decoration: const InputDecoration(
                  labelText: 'Asignar vendedor',
                ),
                items: sellers
                    .map<DropdownMenuItem<int>>(
                      (s) => DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text(s['name']),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedSellerId = value;
                },
              ),
                if (role == 'seller') ...[
                  TextField(
                    controller: commissionController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Comisión (%)',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: documentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Documento',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                    ),
                  ),
                ],

                if (role == 'operador') ...[
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                    ),
                  ),

                  TextField(
                    controller: documentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Documento',
                    ),
                  ),

                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                    ),
                  ),

                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                    ),
                  ),
                ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (role == 'client') {
                  await AdminUserService.updateUser(
                    userId: userData['id'],
                    sellerId: selectedSellerId,
                  );
                }

                if (role == 'seller') {
                  await AdminUserService.updateUser(
                    userId: userData['id'],
                    commissionRate:
                        double.tryParse(commissionController.text),
                    phone: phoneCtrl.text,
                    documentId: documentCtrl.text,
                    city: cityCtrl.text,
                    address: addressCtrl.text,
                  );
                }

                if (role == 'operador') {
                  await AdminUserService.updateUser(
                    userId: userData['id'],
                    phone: phoneCtrl.text,
                    documentId: documentCtrl.text,
                    city: cityCtrl.text,
                    address: addressCtrl.text,
                  );
                }

                Navigator.pop(context);
              } catch (_) {}
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
