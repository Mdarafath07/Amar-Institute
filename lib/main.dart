import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
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
    print('BACKGROUND HANDLER ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    tz.initializeTimeZones();
    await Hive.initFlutter();
    await Hive.openBox('chat_history');

    await Firebase.initializeApp().timeout(const Duration(seconds: 5));

    ClassNotificationService().initialize().catchError((e) {
      debugPrint("Notification Initialization Error: $e");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      _handleIncomingNotification(message);
    });

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    _subscribeToUserTopics();

    debugPrint(' App initialization successful');
  } catch (e) {
    debugPrint(' Initialization Error: $e');
  }

  runApp(const AmarInstitute());
}

Future<void> _handleIncomingNotification(RemoteMessage message) async {
  try {
    final data = message.data;
    final type = data['type'] ?? 'general';

    print(' Notification data: $data');

    if (type == 'notice') {
      final notificationService = ClassNotificationService();

      Map<String, String> payload = {};
      data.forEach((key, value) {
        payload[key] = value.toString();
      });

      await notificationService.sendNoticeNotification(
        title: data['title'] ?? message.notification?.title ?? 'নতুন নোটিশ',
        body: data['body'] ?? message.notification?.body ?? 'বিস্তারিত জানতে ক্লিক করুন',
        payload: payload,
      );

    } else {
      FirebaseMessagingService().handleForegroundMessage(message);
    }
  } catch (e) {
    print(' Error handling notification: $e');
  }
}

Future<void> _subscribeToUserTopics() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final dept = prefs.getString('user_department') ?? '';
    final sem = prefs.getString('user_semester') ?? '';

    if (dept.isNotEmpty && sem.isNotEmpty) {
      final messaging = FirebaseMessaging.instance;

      await messaging.subscribeToTopic('all_users');

      final deptTopic = 'dept_${dept.toLowerCase().replaceAll(' ', '_')}';
      await messaging.subscribeToTopic(deptTopic);

      final semTopic = 'sem_${sem.toLowerCase().replaceAll(' ', '_')}';
      await messaging.subscribeToTopic(semTopic);

      final specificTopic = 'dept_${dept.toLowerCase().replaceAll(' ', '_')}_sem_${sem.toLowerCase().replaceAll(' ', '_')}';
      await messaging.subscribeToTopic(specificTopic);

      print('Subscribed to topics: all_users, $deptTopic, $semTopic, $specificTopic');
    }
  } catch (e) {
    print(' Error subscribing to topics: $e');
  }
}