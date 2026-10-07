import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';

/// Kahan se location aayi: live GPS, saved (offline) ya default.
enum LocationSource { live, saved, defaultFallback }

class SmartLocationService {
  static const String _latKey = 'saved_latitude';
  static const String _lngKey = 'saved_longitude';

  // Default: Dehradun
  static const double _defaultLat = 30.3165;
  static const double _defaultLng = 78.0322;

  /// Last call me location kahan se mili (UI me dikhane ke liye).
  static LocationSource lastSource = LocationSource.defaultFallback;

  /// Last error (agar live GPS fail hua).
  static String? lastError;

  // 1. Save Location
  static Future<void> saveLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
    debugPrint('Location saved: $lat, $lng');
  }

  // 2. Saved location
  static Future<Map<String, double>?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat != null && lng != null) {
      return {'latitude': lat, 'longitude': lng};
    }
    return null;
  }

  // 3. Live GPS -> Saved -> Default
  // Return type same hai, purane callers break nahi honge.
  static Future<Map<String, double>> getBestLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      await saveLocation(position.latitude, position.longitude);
      lastSource = LocationSource.live;
      lastError = null;
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      lastError = e.toString();
      debugPrint('Live GPS failed: $e');

      final saved = await getSavedLocation();
      if (saved != null) {
        lastSource = LocationSource.saved;
        return saved;
      }

      lastSource = LocationSource.defaultFallback;
      return {'latitude': _defaultLat, 'longitude': _defaultLng};
    }
  }

  /// Background worker / adhan scheduler me sirf ye use karo
  /// (background me permission dialog nahi aa sakta).
  static Future<Map<String, double>> getOfflineLocation() async {
    final saved = await getSavedLocation();
    return saved ?? {'latitude': _defaultLat, 'longitude': _defaultLng};
  }
}