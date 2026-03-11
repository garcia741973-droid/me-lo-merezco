import 'package:flutter/material.dart';

import '../../core/services/admin_service.dart';
import 'create_admin_screen.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
 State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {

  List admins = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {

    try {

      final data = await AdminService.fetchAdmins();

      if (!mounted) return;

      setState(() {
        admins = data;
        loading = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error cargando administradores'),
        ),
      );
    }

  }

  Future<void> _resetPasswordDialog(int id) async {

    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {

        return AlertDialog(
          title: const Text("Reset password"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Nueva contraseña",
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancelar"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Guardar"),
            ),

          ],
        );
      },
    );

    if (confirmed != true) return;

    try {

      await AdminService.resetPassword(
        id: id,
        newPassword: controller.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contraseña actualizada"),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error cambiando contraseña"),
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Administradores"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateAdminScreen(),
            ),
          );

          if (created == true) {
            _loadAdmins();
          }

        },
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: admins.length,
              itemBuilder: (context, index) {

                final admin = admins[index];
                final id = admin['id'];
                final isActive = admin['is_active'] == true;

                return ListTile(

                  leading: const Icon(Icons.admin_panel_settings),

                  title: Text(admin['name'] ?? ''),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(admin['email'] ?? ''),

                      Text(
                        isActive ? "Activo" : "Desactivado",
                        style: TextStyle(
                          color: isActive
                              ? Colors.green
                              : Colors.red,
                          fontSize: 12,
                        ),
                      ),

                    ],
                  ),

                  trailing: PopupMenuButton<String>(

                    onSelected: (value) async {

                      try {

                        if (value == 'activate') {

                          await AdminService.activateAdmin(id);

                        }

                        if (value == 'deactivate') {

                          await AdminService.deactivateAdmin(id);

                        }

                        if (value == 'delete') {

                          await AdminService.deleteAdmin(id);

                        }

                        if (value == 'reset') {

                          await _resetPasswordDialog(id);

                        }

                        _loadAdmins();

                      } catch (e) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error ejecutando acción"),
                          ),
                        );

                      }

                    },

                    itemBuilder: (context) {

                      return [

                        if (isActive)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Desactivar'),
                          ),

                        if (!isActive)
                          const PopupMenuItem(
                            value: 'activate',
                            child: Text('Activar'),
                          ),

                        const PopupMenuItem(
                          value: 'reset',
                          child: Text('Reset password'),
                        ),

                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),

                      ];

                    },

                  ),

                );
              },
            ),

    );
  }
}