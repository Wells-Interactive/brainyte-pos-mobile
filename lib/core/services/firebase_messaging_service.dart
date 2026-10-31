import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';

const _orderAlertChannelId = 'brainyte_order_alert_v2';
const _orderAlertChannelName = 'Urgent order alerts';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessagingService.showDataMessageAlert(message, fullScreen: true);
}

/// Data-only FCM handler. Every visible alert is produced locally so the
/// configured urgent channel and custom sound are always used.
class FirebaseMessagingService {
  FirebaseMessagingService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> initialize() async {
    await _initializeLocalNotifications(requestPermissions: true);
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notifications are not authorised.');
    }

    final token = await _messaging.getToken();
    if (token != null) await _sendTokenToBackend(token);
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);
    FirebaseMessaging.onMessage.listen(
      (message) => showDataMessageAlert(message, fullScreen: false),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<void> _initializeLocalNotifications({
    required bool requestPermissions,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestCriticalPermission: false,
      ),
    );
    await plugin.initialize(settings: settings);

    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _orderAlertChannelId,
        _orderAlertChannelName,
        description: 'Loud alerts for new and urgent restaurant orders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('order_alert_5s'),
      ),
    );
    if (requestPermissions) {
      await android?.requestNotificationsPermission();
      await android?.requestFullScreenIntentPermission();
    }
  }

  static Future<void> showDataMessageAlert(
    RemoteMessage message, {
    required bool fullScreen,
  }) async {
    // Standard FCM notification payloads are intentionally ignored.
    final data = message.data;
    if (data.isEmpty) return;

    await _initializeLocalNotifications(requestPermissions: false);
    final title = data['title']?.trim().isNotEmpty == true
        ? data['title']!
        : 'Order update';
    final body = data['body']?.trim().isNotEmpty == true
        ? data['body']!
        : 'A restaurant order needs attention.';
    final eventType = data['event_type'] ?? data['reference_type'] ?? '';
    final isOrder = eventType == 'order';

    final android = AndroidNotificationDetails(
      _orderAlertChannelId,
      _orderAlertChannelName,
      channelDescription: 'Loud alerts for new and urgent restaurant orders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('order_alert_5s'),
      enableVibration: true,
      ticker: 'Urgent restaurant order',
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: fullScreen && isOrder,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'order_alert_5s.wav',
      interruptionLevel: InterruptionLevel.critical,
      criticalSoundVolume: 1.0,
    );
    await FlutterLocalNotificationsPlugin().show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: android, iOS: ios),
      payload: data['reference_id'],
    );
  }

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
    } catch (error) {
      debugPrint('Failed to save FCM token: $error');
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Opened from order notification: ${message.data}');
  }

  Future<String?> getToken() => _messaging.getToken();
  Future<void> subscribeToTopic(String topic) => _messaging.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) => _messaging.unsubscribeFromTopic(topic);
}
