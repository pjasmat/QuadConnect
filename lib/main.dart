import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
}

void main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (critical path - optimize)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service (non-blocking)
  final notificationService = NotificationService();
  // Initialize in background to not block app startup
  notificationService.initialize().catchError((error) {
    print('Error initializing notifications: $error');
  });

  // Run app immediately
  runApp(const QuadConnect());
}

class QuadConnect extends StatelessWidget {
  const QuadConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuadConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
