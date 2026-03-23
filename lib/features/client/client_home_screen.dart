import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/auth_service.dart';
import '../auth/auth_gate.dart';
import '../auth/change_password_screen.dart';

import 'client_orders_screen.dart';
import 'client_offers_screen.dart';
import 'client_main_menu_screen.dart';

import '../communications/screens/chat_screen.dart';
import 'client_help_screen.dart';
import 'package:http/http.dart' as http;

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _bottomIndex = 0;

  // ✅ NUEVO (NO rompe nada)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // ✅ CACHE DE PANTALLAS (soluciona cierre del drawer)
    _pages = const [
      ClientMainMenuScreen(),
      ClientOrdersScreen(),
      ClientOffersScreen(),
    ];
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar cuenta"),
        content: const Text(
          "¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      final token = await AuthService().getToken();

      final response = await http.delete(
        Uri.parse(
          "https://me-lo-merezco-backend.onrender.com/auth/delete-account",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        await AuthService().logout();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    } catch (e) {
      print("Error eliminando cuenta $e");
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  // 🔹 NO TOCADO (lo dejamos por seguridad)
  Widget _currentView() {
    switch (_bottomIndex) {
      case 1:
        return const ClientOrdersScreen();
      case 2:
        return const ClientOffersScreen();
      default:
        return const ClientMainMenuScreen();
    }
  }

  void _closeDrawer(BuildContext drawerContext) {
    Navigator.pop(drawerContext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
// SOLO TE PONGO LA PARTE DEL DRAWER CORREGIDA

        endDrawer: Drawer(
          child: Builder(
            builder: (drawerContext) {
              return SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const DrawerHeader(
                      child: Text(
                        'Menú',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      title: const Text('Menú General'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        setState(() => _bottomIndex = 0);
                      },
                    ),

                    ListTile(
                      title: const Text('Ofertas'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        setState(() => _bottomIndex = 2);
                      },
                    ),

                    ListTile(
                      title: const Text('Carrito / Pedidos'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        setState(() => _bottomIndex = 1);
                      },
                    ),

                    ListTile(
                      title: const Text('Ayuda'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClientHelpScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    ListTile(
                      title: const Text('Política de privacidad'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        _openUrl("https://minicore.estuvia.org/melomerezco/privacy.html");
                      },
                    ),

                    ListTile(
                      title: const Text('Términos de uso'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        _openUrl("https://minicore.estuvia.org/melomerezco/terms.html");
                      },
                    ),

                    ListTile(
                      title: const Text('Soporte'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        _openUrl("https://minicore.estuvia.org/melomerezco/support.html");
                      },
                    ),

                    const Divider(),

                    ListTile(
                      title: const Text('Eliminar cuenta'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        _confirmDeleteAccount();
                      },
                    ),

                    ListTile(
                      title: const Text('Salir'),
                      onTap: () {
                        Navigator.pop(drawerContext);
                        _logout();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      appBar: AppBar(
        title: const Text('Me lo merezco'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              final user = AuthService().currentUser;
              if (user == null) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: 1,
                    currentUserId: user.id,
                  ),
                ),
              );
            },
          ),

          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),

      // ✅ SOLO CAMBIO REAL
      body: SafeArea(
        child: IndexedStack(
          index: _bottomIndex,
          children: _pages,
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Menú',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Ofertas',
          ),
        ],
      ),
    );
  }
}