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

  // Saari screens apni sahi jagah par hain
  final List<Widget> _screens = [
    const ScheduleScreen(),
    const PrayerScreen(), // 🕌 2nd Tab: Prayers Tracker
    const QuranScreen(),  // 📖 3rd Tab: Quran Tracker
    const LifeScreen(),   // ✨ 4th Tab: Life (Habits & Mood Tracker)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ extendBody ko true kiya taaki background (jaise diary ka panna) nav bar ke peeche tak smooth dikhe
      extendBody: true, 
      body: _screens[_currentIndex],
      
      // ✨ Nayi Floating Premium Nav Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withOpacity(0.15), // Soft glowing shadow
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed, 
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryPink,
              unselectedItemColor: AppTheme.textLight.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              elevation: 0, // Default elevation zero kyunki humne Container mein pyara shadow lagaya hai
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.favorite_border)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.favorite)),
                  label: 'Routine', 
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.mosque_outlined)), 
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.mosque)),
                  label: 'Prières', // ✨ French touch
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.menu_book_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.menu_book)),
                  label: 'Coran', // ✨ French touch
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.water_drop_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.water_drop)),
                  label: 'Vie', // ✨ French touch
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}