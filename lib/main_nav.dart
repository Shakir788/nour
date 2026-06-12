import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/schedule/presentation/schedule_screen.dart';
import 'features/prayer/presentation/prayer_screen.dart'; 
import 'features/quran/presentation/quran_screen.dart';
import 'features/habits/presentation/life_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  // Saari screens ab sahi jagah par hain
  final List<Widget> _screens = [
    const ScheduleScreen(),
    const PrayerScreen(), // 🕌 2nd Tab: Prayers Tracker
    const QuranScreen(),  // 📖 3rd Tab: Quran Tracker
    const LifeScreen(),   // ✨ 4th Tab: Life (Habits & Mood Tracker)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Taki saare icons dikhein
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryPink,
        unselectedItemColor: AppTheme.textLight,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Routine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mosque_outlined), 
            activeIcon: Icon(Icons.mosque),
            label: 'Prayers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Quran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_outlined),
            activeIcon: Icon(Icons.water_drop),
            label: 'Life',
          ),
        ],
      ),
    );
  }
}