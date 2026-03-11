import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

import 'features/intro/splash_minicore.dart';
import 'app_entry_point.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core/services/auth_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ✅ CONTADOR SEGURO PARA ANDROID (32-bit safe)
int _notificationIdCounter = 0;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('Local notification tapped. Payload: ${response.payload}');
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await _initLocalNotifications();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('User granted permission: ${settings.authorizationStatus}');

  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM TOKEN: $fcmToken');

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint('🔥 TOKEN REFRESHED: $newToken');

    final auth = AuthService();
    final token = await auth.getToken();

    if (token != null) {
      await http.post(
        Uri.parse('https://me-lo-merezco-backend.onrender.com/devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': newToken,
          'platform': 'ios',
        }),
      );
    }
  });

  // ✅ FOREGROUND HANDLER CORREGIDO
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

debugPrint("🔥 PUSH RECIBIDO EN FOREGROUND");

    debugPrint('onMessage received: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    debugPrint('Notification: ${message.notification}');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.message,
      fullScreenIntent: false,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // ✅ ID SEGURO
    _notificationIdCounter++;

    await flutterLocalNotificationsPlugin.show(
      _notificationIdCounter,
      message.notification?.title ?? message.data['title'] ?? 'Notificación',
      message.notification?.body ?? message.data['body'] ?? '',
      notificationDetails,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification clicked: ${message.messageId}');
    debugPrint('onMessageOpenedApp data: ${message.data}');
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