import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Note: Local notifications require flutter_local_notifications package
    // For now, we'll use Firebase Messaging's built-in notification handling

    // Get FCM token and save to Firestore
    await _saveTokenToFirestore();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle notification when app is opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(token: newToken);
    });
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore({String? token}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final fcmToken = token ?? await _messaging.getToken();
    if (fcmToken == null) return;

    await _db.collection('users').doc(uid).update({
      'fcmToken': fcmToken,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');
    // Firebase Messaging will show notifications automatically
    // For custom handling, you can show a dialog or snackbar here
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
    // Navigate to appropriate screen based on message data
    // This will be handled by the app's navigation system
  }

  // Send notification to a user (for testing or admin use)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final fcmToken = userData?['fcmToken'] as String?;
    if (fcmToken == null) return;

    // In a real app, you'd use Cloud Functions or a backend server
    // to send notifications. For now, we'll just log it.
    print('Would send notification to $userId: $title - $body');
    // TODO: Implement Cloud Functions endpoint to send FCM messages
  }

  // Delete token on logout
  Future<void> deleteToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}

// Top-level function for background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  // Handle background message here
}
