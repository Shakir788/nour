import 'package:flutter/material.dart';

class GreetingHelper {
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good morning Habibati ❤️";
    } else if (hour >= 12 && hour < 17) {
      return "Have a lovely afternoon 🌸";
    } else if (hour >= 17 && hour < 21) {
      return "Good evening, breathe in peace ✨";
    } else {
      return "Rest well, proud of you 🌙";
    }
  }

  // Cute subtitle logic
  static String getSubtitle() {
    final hour = DateTime.now().hour;
    if (hour >= 21 || hour < 5) {
      return "Time to wind down and relax.";
    }
    return "Let's make today beautiful.";
  }
}