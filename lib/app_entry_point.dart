import 'package:flutter/material.dart';
import 'features/auth/auth_gate.dart';
import 'features/intro/splash_minicore.dart';
import 'core/services/auth_service.dart';

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool? _hasValidSession;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final ok = await AuthService().fetchCurrentUserFromToken();
    if (!mounted) return;

    setState(() {
      _hasValidSession = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mientras valida sesión
    if (_hasValidSession == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si hay sesión válida → AuthGate decide destino final
    if (_hasValidSession == true) {
      return const AuthGate();
    }

    // Si NO hay sesión → mostrar intro premium
    return const SplashMiniCore();
  }
}