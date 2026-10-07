import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

import 'smart_location_service.dart';

class AdhanScheduler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Naye IDs: 90000+ (NotificationService ke 2000+/3000+ se takkar nahi hogi)
  static const int _idBase = 90000;

  static bool _running = false;
  static DateTime? _lastScheduledAt;

  // ─────────────────────────────────────────────
  // INIT
  // Background (WorkManager) me requestPermissions: false do,
  // kyunki wahan koi screen nahi hoti.
  // ─────────────────────────────────────────────
  static Future<void> init({bool requestPermissions = true}) async {
    tzData.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    if (requestPermissions) {
      try {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('⚠️ Permission request failed: $e');
      }
    }
  }

  // ─────────────────────────────────────────────
  // LOCATION
  // Foreground: live GPS -> saved. Dono na mile to error (galat jagah ki adhan nahi).
  // Background: sirf saved location.
  // ─────────────────────────────────────────────
  static Future<Coordinates> _getCoordinates({required bool background}) async {
    if (!background) {
      final loc = await SmartLocationService.getBestLocation();
      if (SmartLocationService.lastSource == LocationSource.defaultFallback) {
        throw Exception(
            'Location nahi mili, adhan schedule nahi ho sakti: ${SmartLocationService.lastError}');
      }
      debugPrint('📍 Adhan location source: ${SmartLocationService.lastSource}');
      return Coordinates(loc['latitude']!, loc['longitude']!);
    }

    final saved = await SmartLocationService.getSavedLocation();
    if (saved == null) {
      throw Exception('Saved location nahi hai (background run).');
    }
    return Coordinates(saved['latitude']!, saved['longitude']!);
  }

  // ─────────────────────────────────────────────
  // 15 DIN KI ADHAN SCHEDULE
  // force: true  -> turant dobara schedule kare
  // force: false -> 30 min ke andar dobara call hone par kuch nahi karta
  // ─────────────────────────────────────────────
  // Return: true = adhan schedule ho gayi (ya abhi-abhi ho chuki thi), false = nahi hui.
  // allowLive: false => sirf saved location use karo (purane callers ke liye)
  static Future<bool> scheduleAdhansForNext15Days({
    bool force = false,
    bool background = false,
    bool allowLive = true,
  }) async {
    if (_running) return false;
    if (!force &&
        _lastScheduledAt != null &&
        DateTime.now().difference(_lastScheduledAt!) <
            const Duration(minutes: 30)) {
      return true;
    }

    _running = true;
    try {
      final Coordinates coords =
          await _getCoordinates(background: background || !allowLive);

      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timezoneName = timezoneInfo.identifier;
      final tz.Location userTz = tz.getLocation(timezoneName);

      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;

      await cancelAllAdhans(allPossibleIds);

      final now = DateTime.now();
      int scheduledCount = 0;

      for (int dayOffset = 0; dayOffset < 15; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));
        final dateComponents =
            DateComponents(targetDate.year, targetDate.month, targetDate.day);

        final PrayerTimes prayerTimes =
            PrayerTimes(coords, dateComponents, params);

        final Map<String, DateTime> prayers = {
          'Fajr': prayerTimes.fajr,
          'Dhuhr': prayerTimes.dhuhr,
          'Asr': prayerTimes.asr,
          'Maghrib': prayerTimes.maghrib,
          'Isha': prayerTimes.isha,
        };

        int i = 1;
        for (final entry in prayers.entries) {
          final ok = await _scheduleAdhan(
            prayerName: entry.key,
            prayerTime: entry.value,
            userTz: userTz,
            notificationId: _idBase + (dayOffset * 10) + i,
          );
          if (ok) scheduledCount++;
          i++;
        }
      }

      _lastScheduledAt = DateTime.now();

      final pending = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint(
        '✅ ADHANS SCHEDULED: $scheduledCount | pending total: ${pending.length} | '
        'Lat: ${coords.latitude.toStringAsFixed(4)} '
        'Lng: ${coords.longitude.toStringAsFixed(4)} | TZ: $timezoneName',
      );
      return true;
    } catch (e) {
      debugPrint('❌ AdhanScheduler Error: $e');
      return false;
    } finally {
      _running = false;
    }
  }

  static Future<bool> _scheduleAdhan({
    required String prayerName,
    required DateTime prayerTime,
    required tz.Location userTz,
    required int notificationId,
  }) async {
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.from(prayerTime, userTz);
      final tz.TZDateTime now = tz.TZDateTime.now(userTz);

      if (scheduledDate.isBefore(now)) return false;

      final String soundFile =
          prayerName.toLowerCase() == 'fajr' ? 'fajr_adhan' : 'normal_adhan';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'adhan_channel_${prayerName.toLowerCase()}_v13',
        'Adhan - $prayerName',
        channelDescription: 'Plays Adhan for $prayerName prayer',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: RawResourceAndroidNotificationSound(soundFile),
        playSound: true,
        autoCancel: true,
        color: const Color(0xFFE0B155),
        largeIcon:
            const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      );

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '🕌 $prayerName',
        'Time for $prayerName prayer',
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
          '✅ SCHEDULED: $prayerName at $scheduledDate (ID: $notificationId)');
      return true;
    } catch (e) {
      // Release me aksar yahan "invalid_sound" aata hai agar res/raw ki file hat gayi ho
      debugPrint('❌ ERROR scheduling $prayerName: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // TEST: 30 second baad adhan bajao (sound + release check ke liye)
  // ─────────────────────────────────────────────
  static Future<void> testAdhan({int seconds = 30}) async {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final userTz = tz.getLocation(timezoneInfo.identifier);
    final ok = await _scheduleAdhan(
      prayerName: 'Test',
      prayerTime: DateTime.now().add(Duration(seconds: seconds)),
      userTz: userTz,
      notificationId: 99999,
    );
    debugPrint(ok
        ? '🧪 Test adhan $seconds sec me bajegi'
        : '🧪 Test adhan schedule NAHI hui (upar ka error dekho)');
  }

  static Future<void> cancelAllAdhans(List<int> ids) async {
    for (final int id in ids) {
      await _notificationsPlugin.cancel(id);
    }
  }

  // Purane IDs (day*100+i) + naye IDs (90000+...) dono
  static List<int> get allPossibleIds {
    final List<int> ids = [];
    for (int day = 1; day <= 31; day++) {
      final int base = day * 100;
      ids.addAll([base + 1, base + 2, base + 3, base + 4, base + 5]);
    }
    for (int d = 0; d < 15; d++) {
      for (int i = 1; i <= 5; i++) {
        ids.add(_idBase + (d * 10) + i);
      }
    }
    return ids;
  }
}