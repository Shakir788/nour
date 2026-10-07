import 'dart:math';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz_local;
import 'package:flutter_timezone/flutter_timezone.dart'; // 🔥 Yahan se local timezone lenge
import 'package:intl/intl.dart';

import 'ai_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // ✨ TERA PREMIUM GOLD COLOR
  static const Color appGold = Color(0xFFD4AF37);

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    // 🔥 FIX: String hata kar TimezoneInfo kar diya aur .identifier laga diya
    final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz_local.setLocalLocation(tz_local.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(initSettings);
    
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // App start hote hi AI aur Smart Duas dono schedule ho jayenge
    await scheduleRandomNotifications();
    await scheduleSmartDuas();
  }

  // ✨ UNSTOPPABLE ALARM VERSION (Namaz / Adhkar Reminder ke liye perfect)
  static Future<void> scheduleRoutineTask(int id, String title, String timeStr, String dateStr) async {
    try {
      final String dateTimeString = "$dateStr $timeStr";
      final DateTime scheduledTime = DateFormat("yyyy-MM-dd HH:mm").parse(dateTimeString);
      final tz_local.TZDateTime tzScheduledTime = tz_local.TZDateTime.from(scheduledTime, tz_local.local);

      if (tzScheduledTime.isBefore(tz_local.TZDateTime.now(tz_local.local))) return;

      await _notificationsPlugin.zonedSchedule(
        id, 
        'NOUR Reminder 🌙', 
        title,
        tzScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'nour_routine_tasks_v2', 
            'Spiritual Routines',
            channelDescription: 'Reminders for your daily prayers and tasks',
            importance: Importance.max,
            priority: Priority.high,
            color: appGold, 
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            sound: const RawResourceAndroidNotificationSound('premium_reminder'), 
            playSound: true,
            additionalFlags: Int32List.fromList(<int>[4]), 
            
            // 🚨 MASTER ALARM SHIELD 🚨
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            fullScreenIntent: true, 
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("✅ Unstoppable Task Scheduled: $title at $tzScheduledTime (ID: $id)");
    } catch (e) {
      debugPrint("❌ Error scheduling routine task: $e");
    }
  }

  static Future<void> cancelRoutineTask(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint("🛑 Task Notification Canceled (ID: $id)");
  }

  // ✨ SMART DUAS
  static Future<void> scheduleSmartDuas() async {
    List<Map<String, String>> smartNotifications = [
      {"title": "Dil udas lag raha hai? 😔", "body": "Allah tumhare sath hai. App khol kar apne sukoon ki dua padho."},
      {"title": "Ghabrahat ho rahi hai? 😰", "body": "Hasbunallah wa ni'mal-wakil. Aao mil kar thoda zikr karein."},
      {"title": "Kya aaj shukar ada kiya? 🌿", "body": "Alhamdulillah kaho, aur NOUR mein apni gratitude dua check karo."},
      {"title": "Ek pal sukoon ka... ❤️", "body": "Apne busy din se 1 minute nikalo aur apne Rab se baat karo."},
    ];

    final Random random = Random();
    DateTime currentTime = DateTime.now();

    for (int i = 0; i < 3; i++) {
      currentTime = currentTime.add(Duration(hours: 3 + random.nextInt(3))); 
      
      if (currentTime.hour >= 22 || currentTime.hour <= 7) {
        currentTime = DateTime(currentTime.year, currentTime.month, currentTime.day + 1, 9, 0);
      }

      final dua = smartNotifications[random.nextInt(smartNotifications.length)];
      int notificationId = 3000 + i; 

      await _notificationsPlugin.zonedSchedule(
        notificationId, 
        dua['title'], 
        dua['body'], 
        tz_local.TZDateTime.from(currentTime, tz_local.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'smart_duas_channel', 
            'Smart Duas', 
            importance: Importance.high,
            priority: Priority.high,
            color: appGold, 
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(
              dua['body']!,
              contentTitle: "<b>${dua['title']}</b>",
              htmlFormatContentTitle: true,
              summaryText: 'Spiritual Reminder 🌙', 
            ),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    debugPrint("✅ Smart Duas Scheduled successfully!");
  }

  // ✨ PRODUCTION MODE: AI Generated Notifications
  static Future<void> scheduleRandomNotifications() async {
    await _cancelOldNotifications();

    List<String> aiMessages = await AIService.getLuluNotificationBatch(); 

    if (aiMessages.isEmpty) return;

    final Random random = Random();
    DateTime currentTime = DateTime.now();
    bool isFirstMessage = true; 

    for (int i = 0; i < aiMessages.length; i++) {
      if (isFirstMessage) {
        currentTime = currentTime.add(const Duration(minutes: 5)); 
        isFirstMessage = false;
      } else {
        currentTime = currentTime.add(Duration(minutes: 60 + random.nextInt(60)));
      }
      
      if (currentTime.hour >= 22 || currentTime.hour <= 7) {
        currentTime = DateTime(currentTime.year, currentTime.month, currentTime.day + 1, 8, 0);
      }

      String msgText = aiMessages[i];
      int notificationId = 2000 + i; 

      try {
        await _notificationsPlugin.zonedSchedule(
          notificationId, 
          'NOUR ✨', 
          msgText, 
          tz_local.TZDateTime.from(currentTime, tz_local.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'nour_daily_channel_v6', 
              'Daily Inspirations', 
              importance: Importance.high,
              priority: Priority.high,
              color: appGold, 
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), 
              styleInformation: BigTextStyleInformation(
                msgText,
                contentTitle: '<b>NOUR ✨</b>',
                htmlFormatContentTitle: true,
                summaryText: 'Spiritual Companion 🌙',
              ),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint("Schedule error: $e");
      }
    }
  }

  static Future<void> _cancelOldNotifications() async {
    for (int i = 0; i < 20; i++) {
      await _notificationsPlugin.cancel(2000 + i);
    }
    for (int i = 0; i < 5; i++) { 
      await _notificationsPlugin.cancel(3000 + i);
    }
  }
}