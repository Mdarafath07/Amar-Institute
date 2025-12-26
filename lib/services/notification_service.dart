import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../models/timetable_model.dart';
import 'firebase_messaging_service.dart';

class ClassNotificationService {
  static final ClassNotificationService _instance = ClassNotificationService._internal();
  factory ClassNotificationService() => _instance;
  ClassNotificationService._internal();

  Timer? _checkTimer;
  bool _isInitialized = false;
  final FirebaseMessagingService fcmService = FirebaseMessagingService();

  // Convert ClassPeriod to payload
  Map<String, String> _classPeriodToPayload(ClassPeriod classPeriod, String type) {
    return {
      'type': type,
      'class_id': classPeriod.courseCode,
      'course_name': classPeriod.courseCode,
      'room': classPeriod.room,
      'instructor': classPeriod.instructor,
      'time': classPeriod.startTime,
      'period': classPeriod.period.toString(),
    };
  }

  Future<void> initializeFallback() async {
    try {
      print('Trying fallback initialization...');

      await AwesomeNotifications().initialize(
        'resource://drawable/amarinstitute',
        [
          NotificationChannel(
            channelKey: 'class_reminders',
            channelName: 'Class Reminders',
            channelDescription: 'Notifications for class schedules',
            defaultColor: const Color(0xFF4F46E5),
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
        ],
        debug: true,
      );

      _isInitialized = true;
      print('✅ Notification service initialized (fallback mode)');
    } catch (e) {
      print('❌ Fallback initialization also failed: $e');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print(' Starting notification service initialization...');

      print('Initializing Firebase Messaging...');
      await fcmService.initialize();

      await fcmService.debugFCMStatus();

      print(' Initializing Awesome Notifications...');
      bool awesomeInitialized = await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'class_reminders',
            channelName: 'Class Reminders',
            channelDescription: 'Notifications for class schedules',
            defaultColor: const Color(0xFF4F46E5),
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            channelShowBadge: true,
            playSound: true,
            enableVibration: true,
            criticalAlerts: true,
            defaultRingtoneType: DefaultRingtoneType.Notification,
            // soundSource: 'resource://raw/res_notification_sound',
          ),
          NotificationChannel(
            channelKey: 'general_notifications',
            channelName: 'General Notifications',
            channelDescription: 'General app notifications',
            defaultColor: const Color(0xFF059669),
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            channelShowBadge: false,
            playSound: true,
            enableVibration: true,
            criticalAlerts: true,
            // soundSource: 'resource://raw/res_notification_sound',
          ),
        ],
        debug: true,
      );

      if (!awesomeInitialized) {
        throw Exception('Awesome Notifications initialization failed');
      }

      // Notification permission
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      print('🔔 Notification permission allowed: $isAllowed');

      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
        print('🔔 Requested notification permission');
      }

      // SharedPreferences ইনিশিয়ালাইজ
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_service_initialized', true);

      // Subscribe to FCM topics if needed
      await fcmService.subscribeToTopic('all_users');
      await fcmService.subscribeToTopic('class_updates');

      _isInitialized = true;
      print(' Notification service initialized successfully with critical alerts');

    } catch (e, stackTrace) {
      print('❌ Error initializing notification service: $e');
      print('Stack trace: $stackTrace');
      await initializeFallback();
    }
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    try {
      print('Sending test notification...');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 8888,
          channelKey: 'class_reminders',
          title: 'Test Notification',
          body: 'This is a test notification to verify background/foreground handling',
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          displayOnBackground: true,
          displayOnForeground: true,
          payload: {
            'type': 'test',
            'timestamp': DateTime.now().toString(),
          },
        ),
      );

      print(' Test notification sent');
    } catch (e) {
      print(' Error sending test notification: $e');
    }
  }


  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required ClassPeriod classPeriod,
    required String type,
  }) async {
    try {
      final payload = _classPeriodToPayload(classPeriod, type);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'class_reminders',
          title: title,
          body: body,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: false,
          displayOnForeground: true,
          displayOnBackground: true,
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.BigText,
          payload: payload,
        ),
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          millisecond: 0,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      print(' Error scheduling: $e');
    }
  }

  Future<void> checkAndScheduleNotifications(List<ClassPeriod> todayClasses) async {
    try {
      print('🔔 Checking and scheduling notifications for ${todayClasses.length} classes...');

      await _clearOldNotifications();

      if (todayClasses.isNotEmpty) {
        final sortedClasses = List<ClassPeriod>.from(todayClasses)
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        await scheduleClassNotifications(sortedClasses);
      } else {
        await sendTestNotification();
      }
    } catch (e) {
      print(' Error checking notifications: $e');
    }
  }

  Future<void> scheduleClassNotifications(List<ClassPeriod> todayClasses) async {
    print('Scheduling notifications for ${todayClasses.length} classes');

    int scheduledCount = 0;

    for (int i = 0; i < todayClasses.length; i++) {
      final classPeriod = todayClasses[i];
      final scheduled = await _scheduleClassReminders(classPeriod, isFirstClass: i == 0);
      if (scheduled) scheduledCount++;
    }

    if (scheduledCount > 0) {
      print(' Scheduled $scheduledCount class reminders');
    }
  }

  Future<bool> _scheduleClassReminders(ClassPeriod classPeriod, {bool isFirstClass = false}) async {
    try {
      final startTime = _parseTimeString(classPeriod.startTime);
      if (startTime == null) return false;

      final now = tz.TZDateTime.now(tz.local);
      bool hasScheduled = false;

      if (isFirstClass) {
        final twoHoursBefore = startTime.subtract(const Duration(hours: 2));


        if (twoHoursBefore.isAfter(now)) {
          await _scheduleSingleNotification(
            id: _generateNotificationId(classPeriod, 1),
            title: _getTwoHourTitle(classPeriod.courseCode),
            body: _getTwoHourMessage(classPeriod, isFirstClass: true),
            scheduledTime: twoHoursBefore,
            classPeriod: classPeriod,
            type: '2_hour_reminder',
          );
          hasScheduled = true;
          debugPrint('Scheduled 2-hour reminder for: ${classPeriod.courseCode}');
        }
      }

      final fiveMinutesBefore = startTime.subtract(const Duration(minutes: 5));
      if (fiveMinutesBefore.isAfter(now)) {
        await _scheduleSingleNotification(
          id: _generateNotificationId(classPeriod, 2),
          title: _getFiveMinuteTitle(),
          body: _getFiveMinuteMessage(classPeriod),
          scheduledTime: fiveMinutesBefore,
          classPeriod: classPeriod,
          type: '5_min_reminder',
        );
        hasScheduled = true;
      }

      if (startTime.isAfter(now)) {
        await _scheduleSingleNotification(
          id: _generateNotificationId(classPeriod, 3),
          title: _getClassStartTitle(classPeriod.courseCode),
          body: _getClassStartMessage(classPeriod),
          scheduledTime: startTime,
          classPeriod: classPeriod,
          type: 'class_start',
        );
        hasScheduled = true;
      }

      return hasScheduled;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return false;
    }
  }

  int _generateNotificationId(ClassPeriod classPeriod, int type) {
    return classPeriod.period * 1000 + type;
  }

  // Cute টাইটেল জেনারেটর
  String _getTwoHourTitle(String courseCode) {
    final titles = [
      ' First Class Alert!',
      ' $courseCode in 2 Hours',
      ' Prepare for First Class',
      ' Early Bird Reminder',
      ' Today\'s First Class',
    ];
    return titles[DateTime.now().millisecond % titles.length];
  }

  String _getFiveMinuteTitle() {
    final titles = [
      ' Hurry Up!',
      ' Almost Time!',
      ' Get Ready Now!',
      ' Quick Reminder!',
      ' Class Starting Soon!',
    ];
    return titles[DateTime.now().millisecond % titles.length];
  }

  String _getClassStartTitle(String courseCode) {
    final titles = [
      ' $courseCode Started!',
      ' Class is Running!',
      ' $courseCode Begins!',
      ' Join $courseCode Now!',
      ' $courseCode in Session!',
    ];
    return titles[DateTime.now().millisecond % titles.length];
  }

  // Cute মেসেজ জেনারেটর
  String _getTwoHourMessage(ClassPeriod classPeriod, {bool isFirstClass = false}) {
    final prefix = isFirstClass ? "Today's first class" : "Class";
    final messages = [
      ' $prefix ${classPeriod.courseCode} starts in 2 hours!\n📍 Room: ${classPeriod.room}\n⏰ Time: ${classPeriod.startTime}\n\n👨‍🏫 Teacher: ${classPeriod.instructor}\n\nGet your notes ready! ',
      ' $prefix ${classPeriod.courseCode} class is coming up!\n📍 Room ${classPeriod.room}\n⏰ Time: ${classPeriod.startTime}\n\n👨‍🏫 Teacher: ${classPeriod.instructor}\n\nPrepare for an amazing class! ',
      ' $prefix ${classPeriod.courseCode} in 2 hours!\n 📍Room: ${classPeriod.room}\n⏰ Time: ${classPeriod.startTime}\n\n👨‍🏫 Teacher: ${classPeriod.instructor}\n\nReview last class notes! ',
    ];
    return messages[DateTime.now().second % messages.length];
  }

  String _getFiveMinuteMessage(ClassPeriod classPeriod) {
    final messages = [
      ' ${classPeriod.courseCode} starts in 5 minutes!\n Hurry to Room ${classPeriod.room}!\n\nDon\'t be late!',
      ' Quick! ${classPeriod.courseCode} in 5 minutes!\n📍 Room ${classPeriod.room}\n\nGrab your stuff and go!',
      ' ${classPeriod.courseCode} is about to start!\n📍 Room ${classPeriod.room}\n\nSee you there!',
      ' 5 minutes to ${classPeriod.courseCode}!\n📍 Room ${classPeriod.room}\n\nLet\'s learn something new! ',
    ];
    return messages[DateTime.now().second % messages.length];
  }

  String _getClassStartMessage(ClassPeriod classPeriod) {
    final messages = [
      '${classPeriod.courseCode} has just started!\n📍 Room ${classPeriod.room}\n\nJoin now and stay focused!',
      '${classPeriod.courseCode} is now Running!\n📍 Room ${classPeriod.room}\n\nTime to learn!',
      '${classPeriod.courseCode} class is in session!\n📍 Room ${classPeriod.room}\n\nDon\'t miss out!',
      '${classPeriod.courseCode} has begun!\n📍 Room ${classPeriod.room}\n\nLet\'s make it productive!',
    ];
    return messages[DateTime.now().second % messages.length];
  }


  Future<void> _clearOldNotifications() async {
    try {
      final now = DateTime.now();
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();

      for (final notification in scheduledNotifications) {
        final schedule = notification.schedule;
        if (schedule != null && schedule is NotificationCalendar) {
          final scheduledDate = DateTime(
            schedule.year ?? now.year,
            schedule.month ?? now.month,
            schedule.day ?? now.day,
            schedule.hour ?? 0,
            schedule.minute ?? 0,
          );


          if (scheduledDate.isBefore(now.subtract(Duration(hours: 1)))) {
            await AwesomeNotifications().cancel(notification.content?.id ?? 0);
            debugPrint('Deleted old notification: ${notification.content?.title}');
          }
        }
      }

      debugPrint('ℹCleaned old notifications, keeping current ones');
    } catch (e) {
      debugPrint('Error in clear notifications: $e');
    }
  }

  tz.TZDateTime? _parseTimeString(String timeStr) {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final cleanedTime = timeStr.trim().toUpperCase();
      final RegExp timeRegExp = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?');
      final match = timeRegExp.firstMatch(cleanedTime);

      if (match == null) return null;

      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String? period = match.group(3);

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      return scheduledTime.isBefore(now) ? scheduledTime.add(const Duration(days: 1)) : scheduledTime;
    } catch (e) {
      return null;
    }
  }



  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('All notifications cancelled');
  }


  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    try {
      final notifications = await AwesomeNotifications().listScheduledNotifications();
      return notifications.map((notification) {
        final content = notification.content;
        final schedule = notification.schedule;

        String scheduledTimeStr = 'N/A';

        if (schedule != null) {
          scheduledTimeStr = schedule.toString();
        }

        return {
          'id': content?.id,
          'title': content?.title,
          'body': content?.body,
          'scheduledTime': scheduledTimeStr,
          'payload': content?.payload,
          'wakeUpScreen': content?.wakeUpScreen,
          'fullScreenIntent': content?.fullScreenIntent,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting scheduled notifications: $e');
      return [];
    }
  }


  void cacheClasses(List<ClassPeriod> classes) {
    print('💾 Caching ${classes.length} classes for notifications');
  }

  Future<String?> getFCMToken() async {
    try {
      return await fcmService.firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }


  Future<void> testFCMNotification() async {
    try {
      print('Testing FCM notification with full screen intent...');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 7777,
          channelKey: 'class_reminders',
          title: 'Test Full Screen Notification',
          body: 'This is a test notification to check full screen intent and wake up screen functionality',
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          displayOnBackground: true,
          displayOnForeground: true,
          payload: {
            'type': 'manual_test',
            'timestamp': DateTime.now().toString(),
            'test': 'full_screen',
          },
        ),
      );

      debugPrint('Test notification created with full screen intent');
    } catch (e, stackTrace) {
      debugPrint('Error creating test notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Dispose
  void dispose() {
    _checkTimer?.cancel();
  }
}