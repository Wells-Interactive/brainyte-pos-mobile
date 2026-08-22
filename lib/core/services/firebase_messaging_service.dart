import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';

/// Firebase messaging service for handling push notifications.
///
/// This service handles:
/// - Foreground message reception
/// - Background message handling
/// - Token management for sending to backend
/// - Notification permission requests
class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize Firebase messaging and set up handlers.
  Future<void> initialize() async {
    // Request permission (iOS/macOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined or has not granted notification permission');
    }

    // Get FCM token and send to backend
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      _sendTokenToBackend(token);
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (cold start from notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.notification?.title}');
    }
  }

  /// Send FCM token to backend for push notifications.
  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiClient.instance.post(
        Endpoints.v1Operations,
        body: {
          'action': 'push.subscribe',
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'web',
        },
      );
      debugPrint('FCM token sent to backend');
    } catch (e) {
      debugPrint('Failed to send FCM token to backend: $e');
    }
  }

  /// Handle foreground message.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
  }

  /// Handle message opened app from background.
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.notification?.title}');
  }

  /// Get the current FCM token.
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}