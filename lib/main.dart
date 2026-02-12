import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 👇 AQUÍ se usa AuthGate
      home: const AuthGate(),

      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}
