import 'package:flutter/material.dart';

class CatHelper {
  // 1. Time ke hisaab se aesthetics backdrops
  static String getCatBackground() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'https://images.unsplash.com/photo-1548247416-ec66f4900b2e?q=80&w=600&auto=format&fit=crop';
    } else if (hour >= 12 && hour < 17) {
      return 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=600&auto=format&fit=crop';
    } else if (hour >= 17 && hour < 21) {
      return 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?q=80&w=600&auto=format&fit=crop';
    } else {
      return 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?q=80&w=600&auto=format&fit=crop';
    }
  }

  // 2. Real Cat Placeholder for Rigging Logic
  // ✨ Dhyan rakhein: Jab aapke paas Douaa ke liye asli video ho, toh use assets mein dalkar yahan link change karein.
  static String realCatAsset = 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3J3NzlrbzZobW9mNnByYW02eW82NHZmeXhveXk1NnA1dWU5dWZtMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/4N4P7PNoB6p74c052w/giphy.gif';

  // 3. Official Google Meow Sound Links (These work reliably)
  static List<String> meowSounds = [
    'https://actions.google.com/sounds/v1/animals/cat_meow_2.ogg',
    'https://actions.google.com/sounds/v1/animals/cat_purr_close.ogg'
  ];

  // 4. Cute Messages
  static List<String> catMessages = [
    "Meow! Let's build your routine! 🐾",
    "Purrr... Don't forget to pause and breathe! 🌸",
    "Meoww! I'm watching you smash your goals! 🥰",
    "Feed me some tasks, human! 🐟",
    "Stay hydrated! Pause and take a sip of water right now! 💧",
    "Proud of you, Habibati! Keep going! ❤️"
  ];
}