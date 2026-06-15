import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✨ Date formatting (fr_FR) ke liye
import 'core/theme/app_theme.dart';
import 'core/services/adhan_scheduler.dart';
import 'package:timezone/data/latest.dart' as tz; // ✨ Timezone database ke liye

// ✨ Nayi Splash Screen import kar li (Agar folder me daali hai to path theek kar lena)
import 'splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ Timezone database load karega (Adhan scheduling error isi se theek hoga)
  tz.initializeTimeZones();

  // ✨ French locale date formatting ke liye (DateFormat('EEEE', 'fr_FR') wagaira)
  await initializeDateFormatting('fr_FR', null);

  // ✨ Notification service start karega
  await AdhanScheduler.init();

  runApp(
    const ProviderScope(
      child: NourApp(),
    ),
  );
}

class NourApp extends StatelessWidget {
  const NourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nour',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      
      // ✨ Yahan MainNav() hata kar SplashScreen() laga diya!
      home: const SplashScreen(),
    );
  }
}