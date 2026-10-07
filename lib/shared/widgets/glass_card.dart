import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// GlassCard — same API as before (padding, margin, opacity) so no call
/// sites break. Only the internal palette changed: deep-purple glass tint
/// with a gold border/glow instead of the old white-tint + pink shadow.
///
/// `opacity` now controls how much of AppColors.surfaceElevated shows —
/// higher opacity = more solid/"done" looking, lower = more see-through.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withOpacity(opacity),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}