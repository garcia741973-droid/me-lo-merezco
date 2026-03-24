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

import 'client_settings_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // menú inferior modal, sin ScaffoldKey

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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final selected = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientSettingsScreen(),
                ),
              );

              if (!mounted || selected == null) return;

              switch (selected) {
                case 'menu':
                  setState(() => _bottomIndex = 0);
                  break;

                case 'offers':
                  setState(() => _bottomIndex = 2);
                  break;

                case 'orders':
                  setState(() => _bottomIndex = 1);
                  break;

                case 'help':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientHelpScreen(),
                    ),
                  );
                  break;

                case 'privacy':
                  _openUrl("https://minicore.estuvia.org/melomerezco/privacy.html");
                  break;

                case 'terms':
                  _openUrl("https://minicore.estuvia.org/melomerezco/terms.html");
                  break;

                case 'support':
                  _openUrl("https://minicore.estuvia.org/melomerezco/support.html");
                  break;

                case 'delete':
                  _confirmDeleteAccount();
                  break;

                case 'logout':
                  _logout();
                  break;
              }
            },
          ),
        ],
      ),

      // ✅ SOLO CAMBIO REAL
        body: SafeArea(
          child: Builder(
            builder: (context) {
              return IndexedStack(
                index: _bottomIndex,
                children: _pages,
              );
            },
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