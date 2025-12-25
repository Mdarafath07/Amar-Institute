import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app/app.dart';
import 'services/notification_service.dart';
import 'services/firebase_messaging_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {

    await Firebase.initializeApp();

    await AwesomeNotifications().initialize(
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

        ),
        NotificationChannel(
          channelKey: 'class_reminders',
          channelName: 'Class Reminders',
          channelDescription: 'Notifications for class schedules',
          defaultColor: const Color(0xFF4F46E5),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          criticalAlerts: true,
        ),
      ],
      debug: false,
    );


    final title = message.notification?.title ?? 'নতুন নোটিফিকেশন';
    final body = message.notification?.body ?? 'মেসেজ চেক করুন';

    final Map<String, String> payload = {};
    message.data.forEach((key, value) {
      payload[key] = value.toString();
    });
    payload['notification_title'] = title;
    payload['notification_body'] = body;
    payload['from_fcm'] = 'true';
    payload['background_processed'] = 'true';
    payload['timestamp'] = DateTime.now().toString();

    // Unique ID
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
        notificationLayout: NotificationLayout.BigText,
        payload: payload,
      ),
    );

    print('BACKGROUND HANDLER: Notification created successfully from background');

  } catch (e, stackTrace) {
    print('❌ BACKGROUND HANDLER ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> main() async {
  // ১. বাইন্ডিং নিশ্চিত করা
  WidgetsFlutterBinding.ensureInitialized();

  try {
    tz.initializeTimeZones();

    // ২. ফায়ারবেস ৫ সেকেন্ডের টাইমআউট সহ
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));

    // ৩. নোটিফিকেশন সার্ভিসকে নন-ব্লকিং করা ( await সরিয়ে দেওয়া হয়েছে )
    ClassNotificationService().initialize().catchError((e) {
      debugPrint("Notification Initialization Error: $e");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      FirebaseMessagingService().handleForegroundMessage(message);
    });

    // ৪. পারমিশন চেক
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    debugPrint('🚀 App initialization triggered successfully');
  } catch (e) {
    debugPrint('❌ Initialization Error: $e');
  }

  // ৫. যে কোনো পরিস্থিতিতে runApp কল হবেই
  runApp(const AmarInstitute());
}