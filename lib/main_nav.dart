import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'core/theme/app_theme.dart';

// ✨ Saari Screens ke Imports
import 'features/home/presentation/home_dashboard_screen.dart'; // NAYA HOME DASHBOARD
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
  // ✨ App khulte hi default index 0 (Home Dashboard) chalega
  int _currentIndex = 0;

  // ✨ Screens ki nayi list (Order wise)
  final List<Widget> _screens = [
    const HomeDashboardScreen(), // 🏠 0. Naya Home Dashboard
    const ScheduleScreen(),      // 📅 1. Purani Routine Screen
    const PrayerScreen(),        // 🕌 2. Prayers Screen
    const QuranScreen(),         // 📖 3. Quran Screen
    const LifeScreen(),          // 💛 4. Life/Journal Screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: _screens[_currentIndex],

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.goldBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.18),
                blurRadius: 20,
                spreadRadius: 2,
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
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.gold,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
              elevation: 0,
              items: const [
                // 🏠 TAB 0: HOME
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.home)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.house_fill)),
                  label: 'Home',
                ),
                // 📅 TAB 1: ROUTINE
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.square_list)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.square_list_fill)),
                  label: 'Routine',
                ),
                // 🕌 TAB 2: PRAYERS
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.mosque_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.mosque)),
                  label: 'Prayers',
                ),
                // 📖 TAB 3: QURAN
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.book)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.book_solid)),
                  label: 'Quran',
                ),
                // 💛 TAB 4: LIFE / JOURNAL
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.heart)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(CupertinoIcons.heart_solid)),
                  label: 'Life',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}