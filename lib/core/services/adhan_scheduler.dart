import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AdhanScheduler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    // ✨ Android 14 ke liye zaroori permissions
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleDailyAdhan({
    required String prayerName,
    required String timeStr, 
    required int notificationId,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      
      // ✨ FIX: Format ko dynamic rakha hai (12h aur 24h dono handle karega)
      DateTime parsedTime;
      try {
        parsedTime = DateFormat("HH:mm").parse(timeStr);
      } catch (e) {
        parsedTime = DateFormat("hh:mm a").parse(timeStr);
      }

      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      // Agar aaj ka time nikal gaya hai, toh agle din schedule karo
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // ✨ FIX: Custom Sound ke liye file extension zaroori nahi hoti
      String soundFile = (prayerName.toLowerCase() == 'fajr') ? 'fajr_adhan' : 'normal_adhan';

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'adhan_channel_$prayerName', // ✨ Unique channel per prayer for better control
        'Adhan Reminders',
        channelDescription: 'Plays beautiful Adhan for $prayerName',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true, // ✨ Screen jagane ke liye
        category: AndroidNotificationCategory.alarm, // ✨ Alarm category
        sound: RawResourceAndroidNotificationSound(soundFile),
        playSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Time for $prayerName 🕌',
        'Morocco Live Time: $timeStr. Log your spiritual progress.',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✨ Strict timing
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint("🚀 Success: $prayerName Scheduled at $timeStr");
    } catch (e) {
      debugPrint("Error scheduling Adhan: $e");
    }
  }
}