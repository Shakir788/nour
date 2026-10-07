import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// PremiumBackground — layered dark-purple background with soft gold glow,
/// evoking the "lit lantern at night" mood from the Ramadan reference,
/// without literal lantern art assets.
class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base vertical gradient — deep purple-black
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
        ),

        // Top-right warm gold glow (main light source)
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 340,
            height: 340,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.heroGlow,
            ),
          ),
        ),

        // Bottom-left faint secondary glow — adds depth, keeps focus on gold
        Positioned(
          bottom: -110,
          left: -90,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.goldMuted.withOpacity(0.10),
                  AppColors.goldMuted.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        SafeArea(child: child),
      ],
    );
  }
}