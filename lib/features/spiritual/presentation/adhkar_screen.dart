import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // ✨ NAYA: Vibration ke liye
import 'package:flutter_animate/flutter_animate.dart'; // ✨ NAYA: Animations
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../data/adhkar_data.dart'; // Apna data import

class DailyAdhkarScreen extends StatelessWidget {
  const DailyAdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tabs: Morning & Evening
      child: PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.back, color: AppColors.gold),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Daily Adhkar',
              style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.surfaceElevated, width: 2)),
                ),
                child: const TabBar(
                  indicatorColor: AppColors.gold,
                  indicatorWeight: 3,
                  labelColor: AppColors.gold,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: [
                    Tab(text: "Morning"),
                    Tab(text: "Evening"),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _buildAdhkarList(morningAdhkar),
              _buildAdhkarList(eveningAdhkar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdhkarList(List<Map<String, dynamic>> adhkarList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: adhkarList.length,
      itemBuilder: (context, index) {
        final adhkar = adhkarList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          // ✨ TERA INTERACTIVE CARD WIDGET
          child: AdhkarInteractiveCard(adhkar: adhkar)
              .animate(delay: (index * 100).ms) // Staggered Animation
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
        );
      },
    );
  }
}

// ✨ NAYA: STATEFUL CARD (Har card apna count yaad rakhega)
class AdhkarInteractiveCard extends StatefulWidget {
  final Map<String, dynamic> adhkar;
  const AdhkarInteractiveCard({super.key, required this.adhkar});

  @override
  State<AdhkarInteractiveCard> createState() => _AdhkarInteractiveCardState();
}

class _AdhkarInteractiveCardState extends State<AdhkarInteractiveCard> {
  late int remainingCount;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    remainingCount = widget.adhkar['count']; // Start with max count (e.g. 3)
  }

  void _onTapCounter() {
    if (remainingCount > 0) {
      // ✨ PRO TOUCH: Haptic Feedback (Vibration)
      HapticFeedback.lightImpact(); 
      
      setState(() {
        remainingCount--;
        if (remainingCount == 0) {
          isCompleted = true;
          HapticFeedback.mediumImpact(); // Jab pura ho jaye to thodi strong vibration
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: isCompleted ? 0.4 : 0.7, // Pura hone par dark ho jayega
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            widget.adhkar['arabic']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 26,
              color: isCompleted ? AppColors.textMuted : Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.adhkar['transliteration']!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isCompleted ? AppColors.textMuted : AppColors.goldLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.adhkar['meaning']!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isCompleted ? AppColors.textMuted.withValues(alpha: 0.5) : AppColors.textPrimary, 
              fontSize: 13
            ),
          ),
          const SizedBox(height: 24),
          
          // ✨ INTERACTIVE COUNTER BUTTON ✨
          GestureDetector(
            onTap: _onTapCounter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? AppColors.gold.withValues(alpha: 0.1) // Completed state bg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted ? AppColors.gold : AppColors.surfaceElevated,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.hand_draw_fill,
                    color: isCompleted ? AppColors.gold : AppColors.goldLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted ? "Completed" : "Read $remainingCount time${remainingCount > 1 ? 's' : ''}",
                    style: TextStyle(
                      color: isCompleted ? AppColors.gold : AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}