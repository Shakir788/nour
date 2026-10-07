import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// A single charity/sadaqah log entry.
class SadaqahEntry {
  final double amount;
  final String note;
  final DateTime date;

  SadaqahEntry({required this.amount, required this.note, required this.date});

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory SadaqahEntry.fromJson(Map<String, dynamic> json) => SadaqahEntry(
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
      );
}

/// Combined state for the three new "real life" wellness features.
class WellnessData {
  final int dhikrCount;
  final int dhikrTarget;
  final String dhikrDate; // yyyy-MM-dd — counter resets when this != today
  final List<SadaqahEntry> sadaqahEntries;
  final Set<String> fastedDates; // yyyy-MM-dd keys

  const WellnessData({
    this.dhikrCount = 0,
    this.dhikrTarget = 33,
    this.dhikrDate = '',
    this.sadaqahEntries = const [],
    this.fastedDates = const {},
  });

  WellnessData copyWith({
    int? dhikrCount,
    int? dhikrTarget,
    String? dhikrDate,
    List<SadaqahEntry>? sadaqahEntries,
    Set<String>? fastedDates,
  }) {
    return WellnessData(
      dhikrCount: dhikrCount ?? this.dhikrCount,
      dhikrTarget: dhikrTarget ?? this.dhikrTarget,
      dhikrDate: dhikrDate ?? this.dhikrDate,
      sadaqahEntries: sadaqahEntries ?? this.sadaqahEntries,
      fastedDates: fastedDates ?? this.fastedDates,
    );
  }
}

class WellnessNotifier extends StateNotifier<WellnessData> {
  WellnessNotifier() : super(const WellnessData()) {
    _load();
  }

  static const _prefsKey = 'nour_wellness_data_v1';

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final today = _today;

    if (raw == null) {
      state = state.copyWith(dhikrDate: today);
      return;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final storedDate = map['dhikrDate'] as String? ?? '';
      final entries = (map['sadaqahEntries'] as List<dynamic>? ?? [])
          .map((e) => SadaqahEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final fasted =
          (map['fastedDates'] as List<dynamic>? ?? []).map((e) => e as String).toSet();

      state = WellnessData(
        // Dhikr count resets automatically on a new day.
        dhikrCount: storedDate == today ? (map['dhikrCount'] as int? ?? 0) : 0,
        dhikrTarget: map['dhikrTarget'] as int? ?? 33,
        dhikrDate: today,
        sadaqahEntries: entries,
        fastedDates: fasted,
      );
    } catch (_) {
      state = state.copyWith(dhikrDate: today);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'dhikrCount': state.dhikrCount,
        'dhikrTarget': state.dhikrTarget,
        'dhikrDate': state.dhikrDate,
        'sadaqahEntries': state.sadaqahEntries.map((e) => e.toJson()).toList(),
        'fastedDates': state.fastedDates.toList(),
      }),
    );
  }

  void incrementDhikr() {
    state = state.copyWith(dhikrCount: state.dhikrCount + 1, dhikrDate: _today);
    _save();
  }

  void resetDhikr() {
    state = state.copyWith(dhikrCount: 0, dhikrDate: _today);
    _save();
  }

  void cycleDhikrTarget() {
    const presets = [33, 99, 100, 1000];
    final currentIndex = presets.indexOf(state.dhikrTarget);
    final next = presets[(currentIndex + 1) % presets.length];
    state = state.copyWith(dhikrTarget: next);
    _save();
  }

  void addSadaqah(double amount, String note) {
    final entry = SadaqahEntry(amount: amount, note: note, date: DateTime.now());
    state = state.copyWith(sadaqahEntries: [...state.sadaqahEntries, entry]);
    _save();
  }

  void toggleFast(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final updated = Set<String>.from(state.fastedDates);
    if (!updated.add(key)) updated.remove(key);
    state = state.copyWith(fastedDates: updated);
    _save();
  }

  bool isFastedOn(DateTime date) =>
      state.fastedDates.contains(DateFormat('yyyy-MM-dd').format(date));

  double get sadaqahThisMonth {
    final now = DateTime.now();
    return state.sadaqahEntries
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  int get fastsThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int count = 0;
    for (int i = 0; i < 7; i++) {
      if (isFastedOn(weekStart.add(Duration(days: i)))) count++;
    }
    return count;
  }
}

final wellnessProvider = StateNotifierProvider<WellnessNotifier, WellnessData>(
  (ref) => WellnessNotifier(),
);