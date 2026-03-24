import 'package:flutter/material.dart';

class ClientSettingsScreen extends StatelessWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Opciones"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🔹 NAVEGACIÓN
          _sectionTitle("Navegación"),
          _item(
            context,
            icon: Icons.home,
            title: "Menú General",
            value: 'menu',
          ),
          _item(
            context,
            icon: Icons.local_offer,
            title: "Ofertas",
            value: 'offers',
          ),
          _item(
            context,
            icon: Icons.shopping_cart,
            title: "Carrito / Pedidos",
            value: 'orders',
          ),

          const SizedBox(height: 20),

          /// 🔹 SOPORTE
          _sectionTitle("Soporte"),
          _item(
            context,
            icon: Icons.help_outline,
            title: "Ayuda",
            value: 'help',
          ),
          _item(
            context,
            icon: Icons.support_agent,
            title: "Soporte",
            value: 'support',
          ),

          const SizedBox(height: 20),

          /// 🔹 LEGAL
          _sectionTitle("Legal"),
          _item(
            context,
            icon: Icons.privacy_tip_outlined,
            title: "Política de privacidad",
            value: 'privacy',
          ),
          _item(
            context,
            icon: Icons.description_outlined,
            title: "Términos de uso",
            value: 'terms',
          ),

          const SizedBox(height: 20),

          /// 🔹 CUENTA
          _sectionTitle("Cuenta"),
          _item(
            context,
            icon: Icons.delete_outline,
            title: "Eliminar cuenta",
            value: 'delete',
            color: Colors.red,
          ),
          _item(
            context,
            icon: Icons.logout,
            title: "Salir",
            value: 'logout',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  /// 🔹 MÉTODOS FUERA DEL BUILD (CLAVE)

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pop(context, value),
      ),
    );
  }
}