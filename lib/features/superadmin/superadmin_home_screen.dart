import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';
import '../auth/login_screen.dart';
import '../admin/admins_screen.dart';

class SuperAdminHomeScreen extends StatelessWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null || user.role != UserRole.superadmin) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Administrador'),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Administradores'),
            subtitle: const Text('Crear, editar o eliminar administradores'),
            trailing: const Icon(Icons.arrow_forward_ios),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: () async {

              await AuthService().logout();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text("Cerrar sesión"),
          )
        ],
      ),
    );
  }
}