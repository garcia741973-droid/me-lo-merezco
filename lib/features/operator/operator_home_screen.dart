import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../shared/models/user.dart';

import '../admin/admin_orders_screen.dart';
import '../auth/login_screen.dart';

class OperatorHomeScreen extends StatelessWidget {
  const OperatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final user = AuthService().currentUser;

    if (user == null || user.role != UserRole.operador) {
      return const LoginScreen();
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Panel Operador"),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text("Pedidos"),
            subtitle: const Text("Revisar pedidos y confirmar pagos"),
            trailing: const Icon(Icons.arrow_forward_ios),

            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminOrdersScreen(),
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