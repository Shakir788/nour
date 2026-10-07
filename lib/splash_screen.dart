import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; // ✨ Naya import

import '../../../core/theme/app_theme.dart';
import '../main_nav.dart';
import 'features/onboarding/onboarding_screen.dart'; 
import '../../../core/services/adhan_scheduler.dart'; // ✨ Naya import
import '../../../core/services/background_worker.dart'; // ✨ Naya import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _bismillahController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _bismillahController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _runTimeline();
  }

  // ✨ NAYA LOGIC: Permissions aur Adhan Schedule karne ka function
  Future<void> _setupAdhanAndPermissions() async {
    try {
      // 1. Android 13+ ke liye Notification Permission
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      
      // 2. Android 12+ ke liye Exact Alarm Permission
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      
      // 3. Battery Optimization bypass (Sabse zaroori)
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      // 4. Permissions milne ke baad Adhan Schedule karo
      await AdhanScheduler.scheduleAdhansForNext15Days();
      await BackgroundWorker.registerDailyAdhanTask();
      
    } catch (e) {
      debugPrint("Adhan Setup Error: $e");
    }
  }

  Future<void> _runTimeline() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _bismillahController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _logoController.forward();
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _textController.forward();

    // ✨ Yahan hum background mein saari permissions aur scheduling nipta lenge
    await _setupAdhanAndPermissions();

    await Future.delayed(const Duration(milliseconds: 1000)); // Thoda extra wait smooth transition ke liye
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? '';

    if (!mounted) return;

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => userName.isEmpty ? const OnboardingScreen() : const MainNav(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 1100),
    ));
  }

  @override
  void dispose() {
    _bismillahController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bismFade = CurvedAnimation(parent: _bismillahController, curve: Curves.easeOutCubic);
    final bismBlur = Tween<double>(begin: 10.0, end: 0.0).animate(bismFade);

    final logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    final logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    final floatY = Tween<double>(begin: -5.0, end: 5.0).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine));

    final textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    final textShift = Tween<double>(begin: 12.0, end: 0.0).animate(textFade);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── BACKGROUND IMAGE LAYER ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/islamic_bg.png',
                fit: BoxFit.cover,
                color: AppColors.background.withValues(alpha: 0.6),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          // Soft gold glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.heroGlow),
            ),
          ),

          // ── FOREGROUND ELEMENTS LAYER ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── BISMILLAH REVEAL ──
                AnimatedBuilder(
                  animation: _bismillahController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: bismFade.value.clamp(0.0, 1.0),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: bismBlur.value, sigmaY: bismBlur.value),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/bismillah.png',
                              height: 80,
                              color: AppColors.goldLight,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "In the name of Allah, the Most Merciful",
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 70),

                // ── NOUR LOGO FLOATING ──
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _floatController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: logoFade.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, floatY.value * logoFade.value),
                        child: Transform.scale(
                          scale: logoScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.goldGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                              border: Border.all(color: AppColors.background.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Icon(CupertinoIcons.sparkles, color: AppColors.background, size: 50),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 50),

                // ── NOUR TYPOGRAPHY ──
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: textFade.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, textShift.value),
                        child: Column(
                          children: [
                            Text(
                              "NOUR",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: 9,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Your Personal Life Companion",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}