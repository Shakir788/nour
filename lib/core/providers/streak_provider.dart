// lib/core/providers/streak_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final streakProvider = StateNotifierProvider<StreakNotifier, int>((ref) {
  return StreakNotifier();
});

class StreakNotifier extends StateNotifier<int> {
  StreakNotifier() : super(1) {
    _initStreak();
  }

  Future<void> _initStreak() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Purani streak aur last open date nikalo
    final lastOpenedStr = prefs.getString('last_opened_date');
    final currentStreak = prefs.getInt('current_streak') ?? 0;

    // Aaj ki date (time hata kar sirf date lenge taaki accurate calculation ho)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastOpenedStr == null) {
      // 🌟 Case 1: App zindagi mein pehli baar khuli hai
      state = 1;
      await prefs.setString('last_opened_date', today.toIso8601String());
      await prefs.setInt('current_streak', 1);
    } else {
      final lastOpened = DateTime.parse(lastOpenedStr);
      final difference = today.difference(lastOpened).inDays;

      if (difference == 0) {
        // 🌟 Case 2: Aaj already khol chuka hai, streak wahi rahegi
        state = currentStreak == 0 ? 1 : currentStreak; // Safety check
      } else if (difference == 1) {
        // 🌟 Case 3: Kal bhi kholi thi, aaj bhi kholi. Streak badhao!
        state = currentStreak + 1;
        await prefs.setString('last_opened_date', today.toIso8601String());
        await prefs.setInt('current_streak', state);
      } else if (difference > 1) {
        // 🌟 Case 4: Ouch! Ek ya usse zyada din miss kar diye. Streak broken! 💔
        state = 1; 
        await prefs.setString('last_opened_date', today.toIso8601String());
        await prefs.setInt('current_streak', 1);
      }
    }
  }
}