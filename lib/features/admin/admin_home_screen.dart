import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../shared/models/user.dart';

import '../auth/login_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_offers_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_financial_screen.dart';

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

    if (user == null || user.role != UserRole.admin) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Stack(
        children: [

          // 🔵 Fondo oscuro elegante
          Positioned.fill(
            child: Image.asset(
              'assets/logos/fondoGeneral1.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // HEADER SOBRIO
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
  children: [
    Expanded(
      child: const Text(
        "Panel Admin.",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
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
)
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [

                        _tile(
                          icon: Icons.shopping_cart,
                          title: 'Pedidos',
                          subtitle:
                              'Aprobar / rechazar ítems',
                          trailing: _buildPendingBadge(),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminOrdersScreen(),
                              ),
                            );
                            _loadPendingCount();
                          },
                        ),

                        const SizedBox(height: 18),

                        _tile(
                          icon: Icons.people,
                          title: 'Usuarios',
                          subtitle:
                              'Vendedores y clientes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminUsersScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        _tile(
                          icon: Icons.local_offer,
                          title: 'Ofertas',
                          subtitle:
                              'Promociones y campañas',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminOffersScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        _tile(
                          icon: Icons.bar_chart,
                          title: 'Informes',
                          subtitle:
                              'Estadísticas del negocio',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminReportsScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        _tile(
                          icon: Icons.attach_money,
                          title:
                              'Configuración Financiera',
                          subtitle:
                              'Tasas, márgenes e importación',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminFinancialScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBadge() {
    if (_loadingPending) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }

    if (_pendingCount <= 0) {
      return const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white70,
        size: 16,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(14),
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

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 30, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white70),
          ],
        ),
      ),
    );
  }
}