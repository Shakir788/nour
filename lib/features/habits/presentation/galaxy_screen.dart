import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
// ✨ Naya Provider jo DB se saari purani entries nikalega
final allJournalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  // Sirf wo entries layenge jisme kuch likha hai ya photo hai
  return await db.query('daily_habits', where: "gratitude_text != '' OR image_path IS NOT NULL");
});

class GalaxyScreen extends ConsumerStatefulWidget {
  const GalaxyScreen({super.key});

  @override
  ConsumerState<GalaxyScreen> createState() => _GalaxyScreenState();
}

class _GalaxyScreenState extends ConsumerState<GalaxyScreen> {
  final Random _random = Random(42); // Seeded random taaki taare apni jagah na badlein

  @override
  Widget build(BuildContext context) {
    final journalsAsync = ref.watch(allJournalsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // ✨ Premium Night Sky Gradient
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0B19), Color(0xFF1A1A3A), Color(0xFF2C1B3D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Ton Ciel Étoilé 🌌", // Your Starry Sky
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(width: 48), // Balancing space
                  ],
                ),
              ),
              const Text("Chaque étoile est un souvenir précieux", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)), // Every star is a precious memory
              const SizedBox(height: 20),

              // Galaxy Interactive Viewer
              Expanded(
                child: journalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink)),
                  error: (err, stack) => Center(child: Text("Erreur: $err", style: const TextStyle(color: Colors.white))),
                  data: (journals) {
                    if (journals.isEmpty) {
                      return const Center(child: Text("Le ciel est encore vide. Écris dans ton journal pour créer des étoiles ✨", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)));
                    }

                    return InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(100),
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Stack(
                        children: [
                          // Background twinkling effect (Dummy small stars)
                          for (int i = 0; i < 50; i++)
                            Positioned(
                              left: _random.nextDouble() * 1000,
                              top: _random.nextDouble() * 1000,
                              child: Container(
                                width: 2, height: 2,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(_random.nextDouble() * 0.5), shape: BoxShape.circle),
                              ),
                            ),
                          
                          // ✨ THE MEMORY STARS ✨
                          ...journals.map((journal) {
                            // Random position for each journal entry
                            double left = 50 + _random.nextDouble() * 300;
                            double top = 50 + _random.nextDouble() * 600;
                            
                            // Check lock status
                            String? unlockDateStr = journal['unlock_date'];
                            bool isLocked = false;
                            if (unlockDateStr != null && unlockDateStr.isNotEmpty) {
                              DateTime unlockDate = DateFormat('yyyy-MM-dd').parse(unlockDateStr);
                              isLocked = unlockDate.isAfter(DateTime.now());
                            }

                            // Star color logic (Random aesthetic colors for now)
                            List<Color> starColors = [AppTheme.primaryPink, Colors.cyanAccent, Colors.purpleAccent, Colors.amberAccent];
                            Color starColor = starColors[_random.nextInt(starColors.length)];

                            return Positioned(
                              left: left,
                              top: top,
                              child: GestureDetector(
                                onTap: () => _showMemoryDialog(context, journal, isLocked),
                                child: Column(
                                  children: [
                                    Container(
                                      width: isLocked ? 20 : 12,
                                      height: isLocked ? 20 : 12,
                                      decoration: BoxDecoration(
                                        color: isLocked ? Colors.grey.shade800 : starColor,
                                        shape: BoxShape.circle,
                                        boxShadow: isLocked ? [] : [BoxShadow(color: starColor.withOpacity(0.8), blurRadius: 15, spreadRadius: 5)],
                                      ),
                                      child: isLocked ? const Icon(Icons.lock_rounded, size: 12, color: Colors.white54) : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat('dd MMM').format(DateTime.parse(journal['date'])),
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ Popup to show the memory when a star is tapped
  void _showMemoryDialog(BuildContext context, Map<String, dynamic> journal, bool isLocked) {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⏳ Capsule scellée jusqu'au ${journal['unlock_date']} !"),
        backgroundColor: Colors.indigo,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Souvenir du ${journal['date']}", style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                journal['gratitude_text'] ?? "Une belle journée silencieuse...",
                style: const TextStyle(fontSize: 16, fontFamily: 'serif', color: AppTheme.textDark),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fermer", style: TextStyle(color: AppTheme.textLight)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
} 