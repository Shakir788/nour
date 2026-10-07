import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/location_service.dart';
import '../../../core/services/smart_location_service.dart';

// ─── Location Provider ───────────────────────────────────────────
// Live GPS -> save kar do. Fail ho to saved location. Kuch bhi na ho to error.
final userLocationProvider = FutureProvider<Position>((ref) async {
  try {
    final pos = await LocationService.getCurrentLocation();
    await SmartLocationService.saveLocation(pos.latitude, pos.longitude);
    return pos;
  } catch (e) {
    debugPrint('Live location failed: $e');
    final saved = await SmartLocationService.getSavedLocation();
    if (saved != null) {
      return Position(
        latitude: saved['latitude']!,
        longitude: saved['longitude']!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
    rethrow;
  }
});

// ─── City Name Provider (Reverse Geocoding) ──────────────────────
final cityNameProvider = FutureProvider<String>((ref) async {
  final position = await ref.watch(userLocationProvider.future);

  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse'
    '?lat=${position.latitude}&lon=${position.longitude}'
    '&format=json&zoom=10',
  );

  try {
    final response = await http.get(url, headers: {
      'User-Agent': 'NourApp/1.0',
    }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['address'];

      if (address != null) {
        final city = address['city'] ??
            address['town'] ??
            address['county'] ??
            address['state'] ??
            'Your Location';
        return city;
      }
    }
  } catch (e) {
    debugPrint('City name failed: $e');
    return 'Local Timings';
  }

  return 'Your Location';
});

// ─── Live Prayer Times — lat/lng se fetch karo ──────────────────
final livePrayerTimesProvider =
    FutureProvider.family<Map<String, String>, DateTime>((ref, date) async {
  final position = await ref.watch(userLocationProvider.future);
  final double lat = position.latitude;
  final double lng = position.longitude;

  final dateStr = DateFormat('dd-MM-yyyy').format(date);

  // FIX: http -> https (release me cleartext block hota hai)
  final url = Uri.parse(
    'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&method=2',
  );

  final response = await http.get(url).timeout(const Duration(seconds: 20));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final timings = data['data']['timings'];
    return {
      'fajr': _formatTime(timings['Fajr']),
      'dhuhr': _formatTime(timings['Dhuhr']),
      'asr': _formatTime(timings['Asr']),
      'maghrib': _formatTime(timings['Maghrib']),
      'isha': _formatTime(timings['Isha']),
    };
  } else {
    throw Exception('Failed to load prayer times (${response.statusCode})');
  }
});

String _formatTime(String time24) {
  final parsedTime = DateFormat('HH:mm').parse(time24.split(' ')[0]);
  return DateFormat('hh:mm a').format(parsedTime);
}

// ─── Daily Ayah ──────────────────────────────────────────────────
final dailyAyahProvider = FutureProvider<Map<String, String>>((ref) async {
  final random = Random();
  final ayahNumber = random.nextInt(6236) + 1;

  // FIX: http -> https
  final url = Uri.parse(
    'https://api.alquran.cloud/v1/ayah/$ayahNumber/editions/quran-uthmani,en.asad',
  );

  final response = await http.get(url).timeout(const Duration(seconds: 20));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final arabicData = data['data'][0];
    final translationData = data['data'][1];

    return {
      'arabic': arabicData['text'],
      'translation': translationData['text'],
      'reference':
          'Surah ${translationData['surah']['englishName']} [${translationData['surah']['number']}:${translationData['numberInSurah']}]',
    };
  } else {
    throw Exception('Failed to load Ayah (${response.statusCode})');
  }
});

// ─── Prayer Day Model ─────────────────────────────────────────────
class PrayerDay {
  final String date;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;

  PrayerDay({
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
  });

  double get completionPercentage {
    int count = 0;
    if (fajr) count++;
    if (dhuhr) count++;
    if (asr) count++;
    if (maghrib) count++;
    if (isha) count++;
    return count / 5;
  }

  PrayerDay copyWith({
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
  }) {
    return PrayerDay(
      date: date,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }
}

// ─── Prayers Notifier ─────────────────────────────────────────────
class PrayersNotifier extends StateNotifier<Map<String, PrayerDay>> {
  PrayersNotifier() : super({});

  PrayerDay getPrayerForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return state[dateStr] ?? PrayerDay(date: dateStr);
  }

  void togglePrayer(DateTime date, String prayerName) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentDay = state[dateStr] ?? PrayerDay(date: dateStr);

    late PrayerDay updatedDay;
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        updatedDay = currentDay.copyWith(fajr: !currentDay.fajr);
        break;
      case 'dhuhr':
        updatedDay = currentDay.copyWith(dhuhr: !currentDay.dhuhr);
        break;
      case 'asr':
        updatedDay = currentDay.copyWith(asr: !currentDay.asr);
        break;
      case 'maghrib':
        updatedDay = currentDay.copyWith(maghrib: !currentDay.maghrib);
        break;
      case 'isha':
        updatedDay = currentDay.copyWith(isha: !currentDay.isha);
        break;
      default:
        return;
    }

    state = {...state, dateStr: updatedDay};
  }
}

final prayersProvider =
    StateNotifierProvider<PrayersNotifier, Map<String, PrayerDay>>((ref) {
  return PrayersNotifier();
});

final selectedPrayerDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());