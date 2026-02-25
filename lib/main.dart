import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

import 'features/intro/splash_minicore.dart';
import 'app_entry_point.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Registrar handler para mensajes en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Pedir permiso (iOS) — muestra diálogo de permiso si es la primera vez
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  // IMPORTANTE: permitir que iOS muestre notificaciones incluso si la app está en foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Obtener el token FCM del dispositivo y mostrarlo (envíalo al backend)
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM TOKEN: $fcmToken');
  // TODO: aquí puedes llamar a tu endpoint /devices para registrar el token en tu backend.
  // Ejemplo (pseudo):
  // await sendTokenToBackend(fcmToken);

  // Escuchar mensajes cuando la app está en foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('onMessage received: ${message.messageId}');
    debugPrint('Notification title: ${message.notification?.title}');
    debugPrint('Notification body: ${message.notification?.body}');
    debugPrint('Message data: ${message.data}');
    // Nota: con setForegroundNotificationPresentationOptions(alert: true, ...) iOS mostrará
    // la notificación por defecto. Si quieres manejarla tú (ej. diálogo o Snackbar),
    // implementa lógica UI aquí o usa flutter_local_notifications.
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashMiniCore(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}