// lib/core/providers/neki_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ye provider pure app me kahin bhi Neki count show aur update kar sakta hai
final nekiProvider = StateNotifierProvider<NekiNotifier, int>((ref) {
  return NekiNotifier();
});

class NekiNotifier extends StateNotifier<int> {
  NekiNotifier() : super(0) {
    _loadNekis();
  }

  // App start hote hi phone ki memory se purani Nekis load karna
  Future<void> _loadNekis() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('total_nekis') ?? 0;
  }

  // Neki badhane ka function
  Future<void> addNekis(int amount) async {
    state += amount; // UI turant update hogi
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_nekis', state); // Phone me hamesha ke liye save
  }
}