import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../mood/presentation/mood_provider.dart';
import '../presentation/habit_provider.dart';
import '../../../shared/widgets/premium_background.dart';
import 'journal_screen.dart'; // Nayi Diary Screen
import 'galaxy_screen.dart';  // ✨ Naya: Galaxy (Aasmaan) Screen

class LifeScreen extends ConsumerStatefulWidget {
  const LifeScreen({super.key});

  @override
  ConsumerState<LifeScreen> createState() => _LifeScreenState();
}

class _LifeScreenState extends ConsumerState<LifeScreen> {
  static const int focusDuration = 1800; 
  int _timeLeft = focusDuration;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _stopTimer();
        ref.read(habitNotifierProvider.notifier).addProjectSession();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() { _isRunning = false; _timeLeft = focusDuration; });
  }

  String get timerString {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Premium Card Style
  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitNotifierProvider);
    final currentMood = ref.watch(moodNotifierProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 80,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Équilibre et Vie 💧', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark, fontSize: 26, letterSpacing: -0.5)),
              Text('Prenez soin de vous (Take care of yourself)', style: TextStyle(fontSize: 13, color: AppTheme.primaryPink, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            // ✨ FEATURE 5: THE GALAXY BUTTON ✨
            IconButton(
              icon: const Icon(Icons.nights_stay_rounded, color: AppTheme.textDark, size: 28),
              tooltip: "Ton Ciel Étoilé",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GalaxyScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: habits == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink))
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                children: [
                  
                  // --- 1. MOOD TRACKER ---
                  const Text('Comment vous sentez-vous ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    decoration: _cardDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMoodEmoji('Heureux', '😊', currentMood?.moodType),  
                        _buildMoodEmoji('Calme', '😌', currentMood?.moodType),    
                        _buildMoodEmoji('Fatigué', '😴', currentMood?.moodType),  
                        _buildMoodEmoji('Triste', '😢', currentMood?.moodType),   
                        _buildMoodEmoji('Stressé', '😫', currentMood?.moodType),  
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- 2. DAILY HABITS ---
                  const Text('Habitudes Quotidiennes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  
                  // Water Tile
                  Container(
                    decoration: _cardDecoration,
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.water_drop_rounded, color: Colors.blue, size: 24),
                      ),
                      title: const Text("Consommation d'Eau", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 15)),
                      subtitle: Text('${habits.waterIntakeMl} ml aujourd\'hui', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textLight, fontSize: 13)),
                      trailing: GestureDetector(
                        onTap: () => ref.read(habitNotifierProvider.notifier).addWater(250),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: AppTheme.primaryPink, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Gym Tile
                  Container(
                    decoration: _cardDecoration,
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.fitness_center_rounded, color: Colors.deepPurple, size: 24),
                      ),
                      title: const Text('Séance de Sport', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 15)),
                      subtitle: Text(habits.gymAttended ? 'Terminé 💪' : 'Pas encore', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textLight, fontSize: 13)),
                      trailing: Switch(
                        value: habits.gymAttended,
                        activeColor: Colors.white,
                        activeTrackColor: AppTheme.primaryPink,
                        onChanged: (val) => ref.read(habitNotifierProvider.notifier).toggleGym(val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- 3. PROJECT TIMER ---
                  Container(
                    decoration: _cardDecoration,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.primaryPink.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.laptop_mac_rounded, size: 32, color: AppTheme.primaryPink),
                        ),
                        const SizedBox(height: 16),
                        const Text('Concentration Projet (30 Min)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text('Sessions terminées aujourd\'hui : ${habits.projectSessions}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryPink, fontSize: 12)),
                        const SizedBox(height: 20),
                        Text(
                          timerString,
                          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppTheme.textDark, letterSpacing: -2),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRunning ? Colors.grey.shade200 : AppTheme.primaryPink,
                              foregroundColor: _isRunning ? AppTheme.textDark : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: _isRunning ? _stopTimer : _startTimer,
                            child: Text(_isRunning ? 'Arrêter' : 'Démarrer (Start)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- 4. NEW JOURNAL ENTRY BUTTON ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const JournalScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFF0F5), Colors.white]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primaryPink.withOpacity(0.3), width: 1.5),
                        boxShadow: [BoxShadow(color: AppTheme.primaryPink.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(color: AppTheme.primaryPink, shape: BoxShape.circle),
                            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Mon Journal Intime", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                                SizedBox(height: 4),
                                Text("Ouvrir pour écrire tes pensées ✨", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryPink, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
      ),
    );
  }

  Widget _buildMoodEmoji(String label, String emoji, String? selectedMood) {
    String englishType = label;
    if(label == 'Heureux') englishType = 'Happy';
    if(label == 'Calme') englishType = 'Calm';
    if(label == 'Fatigué') englishType = 'Tired';
    if(label == 'Triste') englishType = 'Sad';
    if(label == 'Stressé') englishType = 'Stressed';

    final isSelected = englishType == selectedMood;
    
    return GestureDetector(
      onTap: () => ref.read(moodNotifierProvider.notifier).setMood(englishType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(20), // Vertical pill shape
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              fontSize: 11, 
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, 
              color: isSelected ? Colors.white : AppTheme.textLight
            )),
          ],
        ),
      ),
    );
  }
}