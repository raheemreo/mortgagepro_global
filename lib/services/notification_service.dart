// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/notifications/providers/notifications_provider.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static late final ProviderContainer container;

  Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('FCM Notification permission status: ${settings.authorizationStatus}');
      }

      // Initialize Firebase In-App Messaging and ensure message display is not suppressed
      try {
        await FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
        if (kDebugMode) {
          print('Firebase In-App Messaging initialized.');
        }
      } catch (e, s) {
        if (kDebugMode) {
          print('Error initializing Firebase In-App Messaging: $e\n$s');
        }
      }

      // 2. Subscribe to general broadcast topic
      await messaging.subscribeToTopic('all_users');

      // 3. Get FCM registration token for debugging/targeting
      final token = await messaging.getToken();
      if (token != null) {
        container.read(fcmTokenProvider.notifier).state = token;
      }
      if (kDebugMode) {
        print('FCM Registration Token: $token');
      }

      // 4. Handle messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('FCM message received in foreground: ${message.notification?.title}');
        }
        _handleIncomingMessage(message);
      });

      // 5. Handle user tapping a notification when the app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('FCM message clicked from background state');
        }
        _handleIncomingMessage(message);
      });

      // 6. Check if the app was opened from a terminated state via a notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('FCM message clicked from terminated state');
        }
        _handleIncomingMessage(initialMessage);
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e\n$s');
      }
    }
  }

  void _handleIncomingMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      final title = notification.title ?? 'New Notification';
      final body = notification.body ?? '';
      
      // Determine category from message payload data or fallback to general
      final category = message.data['category'] ?? 'general';
      
      // Add notification to persistent Hive store via Riverpod
      container.read(notificationsProvider.notifier).addNotification(
        title,
        body,
        category: category,
        data: Map<String, dynamic>.from(message.data),
      );
    }
  }
}
