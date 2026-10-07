import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_background.dart';
import '../../../shared/widgets/glass_card.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // Ghaziabad/Delhi NCR ke liye approximate Qibla direction (260.8 degrees)
  // Future mein isko GPS/Geolocator se dynamic kar denge.
  final double qiblaDirection = 260.8; 
  bool _hasVibrated = false;

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: AppColors.gold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Qibla Direction',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Sensor Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }

            double? heading = snapshot.data?.heading;

            if (heading == null) {
              return const Center(
                child: Text(
                  'Compass not supported on this device.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            // ✨ MAGIC: Check if phone is aligned with Qibla (±2 degrees accuracy)
            bool isAligned = (heading - qiblaDirection).abs() < 2 || (heading - qiblaDirection).abs() > 358;
            
            if (isAligned && !_hasVibrated) {
              HapticFeedback.heavyImpact(); // Boom! Vibrate when aligned
              _hasVibrated = true;
            } else if (!isAligned) {
              _hasVibrated = false;
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Status Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isAligned ? "You are facing the Qibla" : "Rotate your phone",
                    key: ValueKey<bool>(isAligned),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: isAligned ? AppColors.gold : AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${heading.toStringAsFixed(0)}°",
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 50),

                // ✨ PREMIUM GLASS COMPASS
                Center(
                  child: GlassCard(
                    opacity: 0.2,
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAligned ? AppColors.gold : AppColors.surfaceElevated, 
                          width: 4
                        ),
                        boxShadow: isAligned 
                          ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)] 
                          : [],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Center Dot
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),

                          // Rotating Dial (Opposite to heading to keep North fixed to real world)
                          Transform.rotate(
                            angle: (heading * -1) * (math.pi / 180),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // North Indicator
                                _buildCompassMarker(0, "N", isPrimary: true),
                                // East, South, West Indicators
                                _buildCompassMarker(90, "E"),
                                _buildCompassMarker(180, "S"),
                                _buildCompassMarker(270, "W"),
                                
                                // ✨ QIBLA POINTER (Kaaba)
                                Transform.rotate(
                                  angle: qiblaDirection * (math.pi / 180),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Transform.translate(
                                      offset: const Offset(0, -25),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.location_solid, 
                                            color: isAligned ? AppColors.gold : AppColors.textSecondary,
                                            size: 32,
                                          ),
                                          const Text("🕋", style: TextStyle(fontSize: 24)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                GlassCard(
                  opacity: 0.6,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    "Place your phone on a flat surface away from magnets.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 13),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  // Compass ki directions (N, E, S, W) banane ke liye helper function
  Widget _buildCompassMarker(double angle, String label, {bool isPrimary = false}) {
    return Transform.rotate(
      angle: angle * (math.pi / 180),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? AppColors.gold : AppColors.textMuted,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              fontSize: isPrimary ? 22 : 16,
            ),
          ),
        ),
      ),
    );
  }
}