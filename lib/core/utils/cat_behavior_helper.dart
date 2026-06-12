import 'package:flutter/material.dart';

class CatBehaviorHelper {
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

  // 2. Interactive Cat Messages (Happy & Angry)
  static Map<String, List<String>> behaviorMessages = {
    'head': [
      "Meow! You are so kind, Douaa! 🐾",
      "Purrr... That feels good! 🌸",
      "Meoww! You are amazing! 🥰",
    ],
    'tail': [
      "Ouch! Careful with my tail! 🐟",
      "Meow! That's not for playing! 💧",
      "Hiss! Don't pull me like that! ❤️",
    ],
    'body': [
      "Meow! Time to tackle your goals! 🐾",
      "Meow! Pause and take a sip of water! 💧",
      "Feed me some tasks, human! 🐟",
    ],
  };

  // 3. Official Google Meow Sound Links
  static Map<String, List<String>> behaviorSounds = {
    'happy': [
      'https://actions.google.com/sounds/v1/animals/cat_meow_2.ogg',
      'https://actions.google.com/sounds/v1/animals/cat_purr_close.ogg',
    ],
    'angry': [
      'https://actions.google.com/sounds/v1/animals/cat_hiss.ogg', 
      'https://actions.google.com/sounds/v1/animals/cat_growl.ogg',
    ],
  };
}