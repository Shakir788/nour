import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AdhanScheduler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> scheduleDailyAdhan({
    required String prayerName,
    required String timeStr, 
    required int notificationId,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      
      final fullDateTimeStr = "$dateStr $timeStr";
      final DateTime prayerDateTime = DateFormat("yyyy-MM-dd hh:mm a").parse(fullDateTimeStr);

      DateTime finalScheduleTime = prayerDateTime;
      if (prayerDateTime.isBefore(now)) {
        finalScheduleTime = prayerDateTime.add(const Duration(days: 1));
      }

      final tz.TZDateTime tzScheduleTime = tz.TZDateTime.from(finalScheduleTime, tz.local);

      String soundFile = (prayerName.toLowerCase() == 'fajr') ? 'fajr_adhan' : 'normal_adhan';

      // ✨ FIX: enableVariables hata diya gaya hai
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'adhan_channel_id',
        'Adhan Reminders',
        channelDescription: 'Plays beautiful Adhan on exact dynamic prayer times',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundFile), 
        playSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Time for $prayerName 🕌',
        'Morocco Live Time: $timeStr. Open your app to log your spiritual progress.',
        tzScheduleTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint("🚀 Successful: $prayerName Scheduled at $timeStr");
    } catch (e) {
      debugPrint("Error scheduling Adhan: $e");
    }
  }
}