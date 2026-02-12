import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../shared/models/user.dart';

import '../auth/login_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_offers_screen.dart';
import 'admin_reports_screen.dart';

import 'admin_offers_screen.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _pendingCount = 0;
  bool _loadingPending = true;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await OrderService.fetchPendingOrdersCount();
      if (!mounted) return;
      setState(() {
        _pendingCount = count;
        _loadingPending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingCount = 0;
        _loadingPending = false;
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
        title: const Text('Panel Admin'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ---------------- PEDIDOS ----------------
            _tile(
              context,
              icon: Icons.shopping_cart,
              title: 'Pedidos',
              subtitle: 'Aprobar / rechazar ítems',
              trailing: _buildPendingBadge(),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminOrdersScreen(),
                  ),
                );
                // 🔁 refresca badge al volver
                _loadPendingCount();
              },
            ),

            const SizedBox(height: 16),

            // ---------------- USUARIOS ----------------
            _tile(
              context,
              icon: Icons.people,
              title: 'Usuarios',
              subtitle: 'Vendedores y clientes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersScreen(),
                  ),
                );
              },
            ),

    // ---------------- OFERTAS ----------------
const SizedBox(height: 16),
_tile(
  context,
  icon: Icons.local_offer,
  title: 'Ofertas',
  subtitle: 'Crear y administrar promociones',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminOffersScreen(),
      ),
    );
  },
),

            const SizedBox(height: 16),


            // ---------------- INFORMES ----------------
            _tile(
              context,
              icon: Icons.bar_chart,
              title: 'Informes',
              subtitle: 'Estadísticas y control del negocio',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildPendingBadge() {
    if (_loadingPending) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_pendingCount <= 0) {
      return const Icon(Icons.arrow_forward_ios);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$_pendingCount',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
