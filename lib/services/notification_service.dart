import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Must be a top-level function — Flutter requires this for background
/// message handling when the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this is called.
  // No UI work can be done here — just data processing if needed.
}

/// Handles all FCM-related setup: permissions, token management,
/// topic subscriptions, and foreground notification display.
class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'campus_connect_alerts';
  static const _channelName = 'CampusConnect Alerts';
  static const _channelDesc = 'Important notices and event updates from CampusConnect';

  static const _androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.high,
  );

  /// Call once from main() before runApp() — registers the background handler
  /// and creates the Android notification channel.
  static Future<void> initializeApp() async {
    // Register background handler (must be before any other FCM call)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Create the high-importance Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Initialize local notifications plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);
  }

  /// Call after the user successfully logs in — requests permission,
  /// saves their FCM token, and subscribes to relevant topics.
  static Future<void> setupForUser({
    required String uid,
    required String department,
  }) async {
    // Request permission (shows dialog on Android 13+ and iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User denied — respect their choice, don't subscribe
    }

    // Subscribe to topics:
    // 'general'        — college-wide notices (all active users)
    // 'dept_{name}'    — department-specific notices
    // 'events_all'     — new events (all active users)
    await _messaging.subscribeToTopic('general');
    await _messaging.subscribeToTopic('events_all');
    if (department.isNotEmpty) {
      final deptTopic =
          'dept_${department.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
      await _messaging.subscribeToTopic(deptTopic);
    }

    // Show a local notification when the app is open (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  /// Call on logout — unsubscribes from all topics so the user no longer
  /// receives notifications after signing out.
  static Future<void> tearDownForUser({required String department}) async {
    await _messaging.unsubscribeFromTopic('general');
    await _messaging.unsubscribeFromTopic('events_all');
    if (department.isNotEmpty) {
      final deptTopic =
          'dept_${department.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
      await _messaging.unsubscribeFromTopic(deptTopic);
    }
  }
}
