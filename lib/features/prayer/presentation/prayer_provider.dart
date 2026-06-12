import 'dart:convert';
import 'dart:math'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../data/prayer_model.dart';

// ✨ API Fetcher ab Date (Calendar) ke hisaab se fetch karega
final livePrayerTimesProvider = FutureProvider.family<Map<String, String>, DateTime>((ref, date) async {
  // Date ko API format (dd-MM-yyyy) mein convert kiya
  final dateStr = DateFormat('dd-MM-yyyy').format(date);
  
  // URL mein dateStr dynamically pass kar diya
  final url = Uri.parse('http://api.aladhan.com/v1/timingsByCity/$dateStr?city=Casablanca&country=Morocco&method=21');
  
  final response = await http.get(url);
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
    throw Exception('Failed to load live times');
  }
});

String _formatTime(String time24) {
  final parsedTime = DateFormat("HH:mm").parse(time24.split(' ')[0]);
  return DateFormat("hh:mm a").format(parsedTime);
}

// ✨ Infinite Random Ayah Fetcher (Updated to French Translation 🇲🇦)
final dailyAyahProvider = FutureProvider<Map<String, String>>((ref) async {
  final random = Random();
  final ayahNumber = random.nextInt(6236) + 1;
  
  // ✨ FIX: en.asad hata kar fr.hamidullah laga diya taaki French mein aaye
  final url = Uri.parse('http://api.alquran.cloud/v1/ayah/$ayahNumber/editions/quran-uthmani,fr.hamidullah');

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final arabicData = data['data'][0];
    final frenchData = data['data'][1]; // French edition

    return {
      'arabic': arabicData['text'],
      'translation': frenchData['text'],
      'reference': 'Sourate ${frenchData['surah']['englishName']} [${frenchData['surah']['number']}:${frenchData['numberInSurah']}]',
    };
  } else {
    throw Exception('Failed to load Ayah');
  }
});

// ✨ FIXED NOTIFIER: Logic ab safe hai
class PrayersNotifier extends StateNotifier<Map<String, PrayerDay>> {
  PrayersNotifier() : super({});

  // Bas data return karo, state mat badlo yahan!
  PrayerDay getPrayerForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return state[dateStr] ?? PrayerDay(date: dateStr);
  }

  // State badalne ka kaam sirf yahan hoga (Button Click par)
  void togglePrayer(DateTime date, String prayerName) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Pehle existing data uthao, agar nahi hai toh naya object banao
    final currentDay = state[dateStr] ?? PrayerDay(date: dateStr);
    
    late PrayerDay updatedDay;
    switch (prayerName.toLowerCase()) {
      case 'fajr': updatedDay = currentDay.copyWith(fajr: !currentDay.fajr); break;
      case 'dhuhr': updatedDay = currentDay.copyWith(dhuhr: !currentDay.dhuhr); break;
      case 'asr': updatedDay = currentDay.copyWith(asr: !currentDay.asr); break;
      case 'maghrib': updatedDay = currentDay.copyWith(maghrib: !currentDay.maghrib); break;
      case 'isha': updatedDay = currentDay.copyWith(isha: !currentDay.isha); break;
      default: return;
    }
    
    // Ab state update karo (Ye safe hai kyunki ye user action hai)
    state = {...state, dateStr: updatedDay};
  }
}

final prayersProvider = StateNotifierProvider<PrayersNotifier, Map<String, PrayerDay>>((ref) {
  return PrayersNotifier();
});

// ✨ NAYA PROVIDER (Calendar date sync karne ke liye)
final selectedPrayerDateProvider = StateProvider<DateTime>((ref) => DateTime.now());