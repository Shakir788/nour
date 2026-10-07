import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart'; // 🔥 YE IMPORT MISSING THA! Iske bina AndroidSettings release me fail hota hai.

class LocationService {
  static Future<Position> getCurrentLocation() async {
    // 1. GPS on hai?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS.');
    }

    // 2. Permission check
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Please enable from settings.');
    }

    // 3. ATTEMPT A: Fused provider (Google Play Services)
    // Ye fast hota hai par release build me kabhi-kabhi hang ho jata hai
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings(forceLocationManager: false),
      );
    } catch (e) {
      debugPrint('⚠️ Fused location failed in release: $e');
    }

    // 4. ATTEMPT B: Android LocationManager (Native Hardware)
    // Google Play Services ko bypass karke direct hardware se nikalega
    if (!kIsWeb && Platform.isAndroid) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: _settings(forceLocationManager: true),
        );
      } catch (e) {
        debugPrint('⚠️ Native LocationManager failed: $e');
      }
    }

    // 5. ATTEMPT C: Last known position (Cache)
    // Agar upar wale dono timeout ho gaye (GF ka net/GPS slow hua), toh crash nahi hoga!
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        debugPrint('✅ Using cached last known position');
        return last;
      }
    } catch (e) {
      debugPrint('⚠️ Last known position failed: $e');
    }

    throw Exception('Failed to get current location (timeout / no GPS fix).');
  }

  // 🛠️ Settings Helper
  static LocationSettings _settings({required bool forceLocationManager}) {
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium, // High ki jagah Medium rakha hai taaki release me timeout na ho
        timeLimit: const Duration(seconds: 10), // 10 sec max wait, uske baad sidha Fallback C par jayega
        forceLocationManager: forceLocationManager,
      );
    }
    
    // Default for iOS / Web
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 10),
    );
  }
}