import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'core/theme/app_theme.dart';
import 'core/services/adhan_scheduler.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_worker.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env not loaded: $e');
  }

  tz.initializeTimeZones();
  await initializeDateFormatting();

  try {
    await NotificationService.init();
    await AdhanScheduler.init();
  } catch (e) {
    debugPrint('Init failed (non-fatal): $e');
  }

  runApp(const ProviderScope(child: NourApp()));

  // App khulte hi (UI block kiye bina) adhan schedule + roz ka auto-reschedule
  unawaited(_startAdhanSystem());
}

// 🧪 TEST MODE: true = 45 sec me test adhan bajegi. Final build se pehle false kar do.
const bool _kRunAdhanTest = false;

Future<void> _startAdhanSystem() async {
  // Test pehle, taaki GPS ke intezaar me der na ho
  if (_kRunAdhanTest) {
    await AdhanScheduler.testAdhan(seconds: 45);
  }

  try {
    await BackgroundWorker.registerDailyAdhanTask();
  } catch (e) {
    debugPrint('WorkManager register failed: $e');
  }

  await AdhanScheduler.scheduleAdhansForNext15Days(force: true);
}

class NourApp extends StatelessWidget {
  const NourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nour',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}