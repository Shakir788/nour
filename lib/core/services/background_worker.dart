import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'adhan_scheduler.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('🔄 WorkManager task started: $taskName');

    try {
      tz.initializeTimeZones();

      if (taskName == BackgroundWorker.adhanTaskName) {
        // Background me permission dialog nahi aa sakta, isliye false
        await AdhanScheduler.init(requestPermissions: false);
        await AdhanScheduler.scheduleAdhansForNext15Days(
          force: true,
          background: true,
        );
      }
    } catch (e) {
      debugPrint('❌ WorkManager task failed: $e');
      return Future.value(false);
    }

    return Future.value(true);
  });
}

class BackgroundWorker {
  static const String adhanTaskName = 'adhan_daily_reschedule';
  static const String adhanUniqueTaskName = 'adhan_unique_daily';

  static Future<void> registerDailyAdhanTask() async {
    await Workmanager().cancelByUniqueName(adhanUniqueTaskName);

    await Workmanager().registerPeriodicTask(
      adhanUniqueTaskName,
      adhanTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: _timeUntilNextRun(),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 30),
    );

    debugPrint('✅ WorkManager: Daily Adhan task registered');
  }

  static Duration _timeUntilNextRun() {
    final now = DateTime.now();
    var next3AM = DateTime(now.year, now.month, now.day, 3, 0);
    if (now.isAfter(next3AM)) {
      next3AM = next3AM.add(const Duration(days: 1));
    }
    final delay = next3AM.difference(now);
    debugPrint(
        '⏰ First run in: ${delay.inHours}h ${delay.inMinutes.remainder(60)}m');
    return delay;
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('🛑 All WorkManager tasks cancelled');
  }
}