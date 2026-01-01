
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
  FirebaseMessagingService._internal();

  factory FirebaseMessagingService() => _instance;

  FirebaseMessagingService._internal();


  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;


  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('FOREGROUND: Message received: ${message.notification?.title}');
      debugPrint('FOREGROUND: Data: ${message.data}');

      final title = message.notification?.title ?? 'নতুন নোটিফিকেশন';
      final body = message.notification?.body ?? 'মেসেজ চেক করুন';


      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      final Map<String, String> payload = {};
      message.data.forEach((key, value) {
        payload[key] = value.toString();
      });


      payload['notification_title'] = title;
      payload['notification_body'] = body;
      payload['from_fcm'] = 'true';
      payload['foreground_processed'] = 'true';
      payload['timestamp'] = DateTime.now().toString();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'general_notifications',
          title: title,
          body: body,
          payload: payload,
          autoDismissible: false,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          displayOnBackground: true,
          displayOnForeground: true,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Message,
        ),
      );

      print('FOREGROUND: Notification created with full screen intent');
    } catch (e, stackTrace) {
      print('FOREGROUND ERROR: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> initialize() async {
    try {
      debugPrint('Initializing Firebase Messaging Service...');


      NotificationSettings settings =
      await firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      print('📱 FCM Permission status: ${settings.authorizationStatus}');


      String? token = await firebaseMessaging.getToken();
      print('📱 FCM Token: $token');


      await _saveTokenToServer(token);


      FirebaseMessaging.onMessage.listen(handleForegroundMessage);


      firebaseMessaging
          .getInitialMessage()
          .then(_handleInitialMessage);


      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);


      await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('Firebase Messaging initialized successfully with enhanced settings');

    } catch (e, stackTrace) {
      debugPrint('FCM initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }


  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      debugPrint('BACKGROUND: Processing background message...');


      if (!await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'general_notifications',
            channelName: 'General Notifications',
            channelDescription: 'General app notifications',
            defaultColor: const Color(0xFF059669),
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            criticalAlerts: true,
            soundSource: 'resource://raw/res_notification_sound',
          ),
        ],
        debug: false,
      )) {
        debugPrint('Failed to initialize AwesomeNotifications in background');
      }

      // Extract notification data
      final title = message.notification?.title ?? 'নতুন নোটিফিকেশন';
      final body = message.notification?.body ?? 'মেসেজ চেক করুন';

      debugPrint('BACKGROUND: Title: $title, Body: $body');

      final Map<String, String> payload = {};
      message.data.forEach((key, value) {
        payload[key] = value.toString();
      });
      payload['notification_title'] = title;
      payload['notification_body'] = body;
      payload['from_fcm'] = 'true';
      payload['background_processed'] = 'true';
      payload['timestamp'] = DateTime.now().toString();

      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'general_notifications',
          title: title,
          body: body,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: false,
          displayOnBackground: true,
          displayOnForeground: true,
          category: NotificationCategory.Message,
          payload: payload,
          notificationLayout: NotificationLayout.BigText,
        ),
      );

      print('BACKGROUND: Notification created with critical alert');
    } catch (e, stackTrace) {
      print('BACKGROUND ERROR: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Private methods
  Future<void> _handleInitialMessage(RemoteMessage? message) async {
    if (message != null) {
      print('App opened from notification: ${message.notification?.title}');
      print('Data: ${message.data}');

      final Map<String, String> payload = {};
      message.data.forEach((key, value) {
        payload[key] = value.toString();
      });

      debugPrint('Payload: $payload');

      if (payload.containsKey('type')) {
        debugPrint('Notification type: ${payload['type']}');
      }
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('📱Message opened from background: ${message.notification?.title}');

    final Map<String, String> payload = {};
    message.data.forEach((key, value) {
      payload[key] = value.toString();
    });

    debugPrint('Payload: $payload');

    if (payload.containsKey('type')) {
      debugPrint(' Handling notification type: ${payload['type']}');
    }
  }

  Future<void> _saveTokenToServer(String? token) async {
    if (token == null) return;

    debugPrint('Saving FCM token to server: $token');
    // TODO: Implement API call to save token to your backend
  }

  // ✅ Public methods
  Future<void> subscribeToTopic(String topic) async {
    try {
      await firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📱 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint(' Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint(' Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await firebaseMessaging.deleteToken();
      debugPrint(' FCM token deleted');
    } catch (e) {
      debugPrint(' Error deleting token: $e');
    }
  }


  Future<void> debugFCMStatus() async {
    try {

      String? token = await firebaseMessaging.getToken();
      print('🔍 DEBUG - FCM Token: $token');

      // Check notification permission
      NotificationSettings settings = await firebaseMessaging.getNotificationSettings();
      debugPrint('🔍 DEBUG - Notification Settings:');
      debugPrint('  - Authorization status: ${settings.authorizationStatus}');
      debugPrint('  - Sound: ${settings.sound}');
      debugPrint('  - Alert: ${settings.alert}');
      debugPrint('  - Badge: ${settings.badge}');
      debugPrint('  - Critical alert: ${settings.criticalAlert}');


      if (token != null) {
        debugPrint('📋 COPY THIS TOKEN FOR TESTING:');
        debugPrint('====================');
        debugPrint(token);
        debugPrint('====================');
      }

    } catch (e) {
      debugPrint('DEBUG Error: $e');
    }
  }

  //  Get FCM token
// আপনার FirebaseMessagingService ক্লাসের getToken মেথডটি নিচের মতো পরিবর্তন করুন:

  Future<String?> getFCMToken() async {
    try {
      // অফলাইনে এটি আটকে থাকে, তাই ৫ সেকেন্ড পর এটি ক্যানসেল হয়ে যাবে
      return await firebaseMessaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('FCM Token request timed out (Offline)');
          return null;
        },
      );
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  //  Test method to verify FCM is working
  Future<void> testFCMNotificationLocal() async {
    try {
      print('🧪 Testing local FCM-like notification...');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 99999,
          channelKey: 'general_notifications',
          title: '🧪 FCM Test Notification',
          body: 'This simulates a Firebase push notification with full screen intent',
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: false,
          displayOnBackground: true,
          displayOnForeground: true,
          payload: {
            'type': 'fcm_test',
            'timestamp': DateTime.now().toString(),
            'test_mode': 'local_simulation',
          },
        ),
      );

      debugPrint('✅ Test FCM notification created');
    } catch (e) {
      debugPrint('❌ Error creating test FCM notification: $e');
    }
  }

  // firebase_messaging_service.dart - এই মেথডটি ক্লাসের শেষে যোগ করুন

  Future<void> sendTargetedNotice({
    required String title,
    required String body,
    required String targetType,
    String? department,
    String? semester,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Prepare FCM message payload
      Map<String, dynamic> messageData = {
        'title': title,
        'body': body,
        'type': 'notice',
        'targetType': targetType,
        'department': department ?? 'all',
        'semester': semester ?? 'all',
        'timestamp': DateTime.now().toIso8601String(),
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'priority': 'high',
      };

      // Add additional data if provided
      if (additionalData != null) {
        messageData.addAll(additionalData);
      }

      // Determine FCM topic based on target
      String topic = _getTargetTopic(targetType, department, semester);

      // Send to FCM (This would typically be done from your backend)
      // For now, we'll create a local notification
      await _createTargetedNotification(title, body, messageData);

      debugPrint('📢 Targeted notice prepared for topic: $topic');

    } catch (e, stackTrace) {
      debugPrint('❌ Error sending targeted notice: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  String _getTargetTopic(String targetType, String? department, String? semester) {
    switch (targetType) {
      case 'all':
        return 'all_users';
      case 'department':
        return 'dept_${department?.toLowerCase() ?? 'all'}';
      case 'semester':
        return 'sem_${semester?.toLowerCase() ?? 'all'}';
      case 'specific':
        return 'dept_${department?.toLowerCase()}_sem_${semester?.toLowerCase()}';
      default:
        return 'all_users';
    }
  }

  Future<void> _createTargetedNotification(
      String title,
      String body,
      Map<String, dynamic> data
      ) async {
    try {
      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      Map<String, String> payload = {};
      data.forEach((key, value) {
        payload[key] = value.toString();
      });

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'general_notifications',
          title: title,
          body: body,
          payload: payload,
          autoDismissible: false,
          wakeUpScreen: true,
          displayOnBackground: true,
          displayOnForeground: true,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Message,
        ),
      );

      debugPrint('✅ Targeted notification created locally');
    } catch (e) {
      debugPrint('❌ Error creating targeted notification: $e');
    }
  }
}