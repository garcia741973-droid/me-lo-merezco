import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../auth/auth_gate.dart';
import '../auth/change_password_screen.dart';

import 'client_orders_screen.dart';
import 'client_offers_screen.dart';
import 'client_main_menu_screen.dart';

import '../communications/screens/chat_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _bottomIndex = 0;

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me lo merezco'),
        actions: [
          // 🔐 Cambiar contraseña
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

          // 💬 Contactar administrador
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              final user = AuthService().currentUser;
              if (user == null) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: 1, // admin único
                    currentUserId: user.id,
                  ),
                ),
              );
            },
          ),

          // ☰ Menú
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'menu':
                  setState(() => _bottomIndex = 0);
                  break;
                case 'offers':
                  setState(() => _bottomIndex = 2);
                  break;
                case 'cart':
                case 'orders':
                  setState(() => _bottomIndex = 1);
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'menu', child: Text('Menú General')),
              PopupMenuItem(value: 'offers', child: Text('Ofertas')),
              PopupMenuItem(value: 'cart', child: Text('Carrito')),
              PopupMenuItem(value: 'orders', child: Text('Pedidos')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Salir')),
            ],
          ),
        ],
      ),
      body: SafeArea(child: _currentView()),
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
